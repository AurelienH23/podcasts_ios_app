//
//  PlayerDetailsView.swift
//  Podcast
//
//  Created by Aurélien Haie on 10/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class PlayerDetailsView: UIView {
    
    // MARK: - Properties
    
    var playlistEpisodes = [Episode]()
    
    var episode: Episode! {
        didSet {
            titleLabel.text = episode.title
            miniTitleLabel.text = episode.title
            authorLabel.text = episode.author
            
            setupNowPlayingInfo()
            
            setupAudioSession()
            playEpisode()
            
            guard let url = URL(string: episode.imageUrl?.toSecureHTTPS() ?? "") else { return }
            episodeImageView.sd_setImage(with: url)
            miniEpisodeImageView.sd_setImage(with: url)
            
            miniEpisodeImageView.sd_setImage(with: url) { (image, _, _, _) in
                guard let image = image else { return }
                
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                
                let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (_) -> UIImage in
                    return image
                })
                
                nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    let player: AVPlayer = {
        let avPlayer = AVPlayer()
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        return avPlayer
    }()
    
    var panGesture: UIPanGestureRecognizer!
    
    fileprivate let shrunkenTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    
    // MARK: - Interface Builder
    
    // Mini View
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var miniEpisodeImageView: UIImageView!
    @IBOutlet weak var miniTitleLabel: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton! {
        didSet {
            miniPlayPauseButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
            miniPlayPauseButton.addTarget(self, action: #selector(handlePlayAndPause), for: .touchUpInside)
        }
    }
    @IBOutlet weak var miniFastForwardButton: UIButton! {
        didSet {
            miniFastForwardButton.imageEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
            miniFastForwardButton.addTarget(self, action: #selector(handleFastForward(_:)), for: .touchUpInside)
        }
    }
    
    // Maximized View
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var episodeImageView: UIImageView! {
        didSet {
            episodeImageView.layer.cornerRadius = 5
            episodeImageView.clipsToBounds = true
            episodeImageView.transform = shrunkenTransform
        }
    }
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.addTarget(self, action: #selector(handlePlayAndPause), for: .touchUpInside)
        }
    }

    @IBAction func handleDismiss(_ sender: Any) {
        UIApplication.mainTabBarController()?.minimizePlayerDetails()
    }

    @IBAction func handleCurrentTimeSliderChange(_ sender: Any) {
        let percentage = currentTimeSlider.value
        
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        let seekTimeInSeconds = Float64(percentage) * durationInSeconds
        
        let seekTime = CMTimeMakeWithSeconds(seekTimeInSeconds, Int32(NSEC_PER_SEC))
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = seekTimeInSeconds
        
        player.seek(to: seekTime)
    }
    
    @IBAction func handleRewind(_ sender: Any) {
        seekToCurrentTime(delta: -15)
    }
    
    @IBAction func handleFastForward(_ sender: Any) {
        seekToCurrentTime(delta: 15)
    }
    
    @IBAction func handleVolumeChanged(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    // MARK: - Lifecycle
    
    static func initFromNib() -> PlayerDetailsView {
        return Bundle.main.loadNibNamed("PlayerDetailsView", owner: self, options: nil)?.first as! PlayerDetailsView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupRemoteControl()
        
        setupAudioSession()
        
        setupGestures()
        
        observePlayerCurrentTime()
        
        observeBoundaryTime()
        
        setupInterruptionObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVAudioSessionInterruption, object: nil)
    }
    
    // MARK: - Custom funcs
    
    fileprivate func setupNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = episode.author
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    fileprivate func setupRemoteControl() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.player.play()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            self.miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            self.setupElapsedTime(playbackRate: 1)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            self.playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            self.miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            self.setupElapsedTime(playbackRate: 0)
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.handlePlayAndPause()
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(handleNextTrack))
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget(self, action: #selector(handlePrevTrack))
    }
    
    @objc fileprivate func handlePrevTrack() {
        if playlistEpisodes.count == 0 {
            return
        }
        
        let currentEpisodeIndex = playlistEpisodes.index { (ep) -> Bool in
            return self.episode.title == ep.title && self.episode.author == ep.author
        }
        
        guard let index = currentEpisodeIndex else { return }
        
        let prevEpisode: Episode
        if index == 0 {
            prevEpisode = playlistEpisodes[playlistEpisodes.count - 1]
        } else {
            prevEpisode = playlistEpisodes[index - 1]
        }
        
        episode = prevEpisode
    }
    
    @objc fileprivate func handleNextTrack() {
        if playlistEpisodes.count == 0 {
            return
        }
        
        let currentEpisodeIndex = playlistEpisodes.index { (ep) -> Bool in
            return self.episode.title == ep.title && self.episode.author == ep.author
        }
        
        guard let index = currentEpisodeIndex else { return }
        
        let nextEpisode: Episode
        if index == playlistEpisodes.count - 1 {
            nextEpisode = playlistEpisodes[0]
        } else {
            nextEpisode = playlistEpisodes[index + 1]
        }
        
        episode = nextEpisode
    }
    
    fileprivate func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print("Failed to activate session: \(err)")
        }
    }
    
    fileprivate func setupGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximize)))
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        miniPlayerView.addGestureRecognizer(panGesture)
        
        maximizedStackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
    }
    
    fileprivate func observeBoundaryTime() {
        let time = CMTimeMake(1, 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            self?.enlargeEpisodeImageView()
            self?.setupLockscreenDuration()
        }
    }
    
    fileprivate func setupLockscreenDuration() {
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
    }
    
    fileprivate func setupElapsedTime(playbackRate: Float) {
        let elapsedTime = CMTimeGetSeconds(player.currentTime())
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
    }
    
    fileprivate func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: .AVAudioSessionInterruption, object: nil)
    }
    
    @objc fileprivate func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt else { return }
        if type == AVAudioSessionInterruptionType.began.rawValue {
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        } else {
            guard let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            if options == AVAudioSessionInterruptionOptions.shouldResume.rawValue {
                player.play()
                playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            }
        }
    }
    
    fileprivate func playEpisode() {
        if episode.fileUrl != nil {
            guard let fileURL = URL(string: episode.fileUrl ?? "") else { return }
            let fileName = fileURL.lastPathComponent
            
            guard var trueLocation = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            trueLocation.appendPathComponent(fileName)
            
            guard let url = URL(string: episode.fileUrl ?? "") else { return }
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.play()
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        } else {
            guard let url = URL(string: episode.streamUrl) else { return }
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.play()
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
    
    @objc func handlePlayAndPause() {
        if player.timeControlStatus == .paused {
            player.play()
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            enlargeEpisodeImageView()
            setupElapsedTime(playbackRate: 1)
        } else {
            player.pause()
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            shrinkEpisodeImageView()
            setupElapsedTime(playbackRate: 0)
        }
    }
    
    fileprivate func enlargeEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = .identity
        })
    }
    
    fileprivate func shrinkEpisodeImageView() {
        UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.episodeImageView.transform = self.shrunkenTransform
        })
    }
    
    fileprivate func seekToCurrentTime(delta: Int64) {
        let deltaSeconds = CMTimeMake(delta, 1)
        let seekTime = CMTimeAdd(player.currentTime(), deltaSeconds)
        player.seek(to: seekTime)
    }
    
    fileprivate func observePlayerCurrentTime() {
        let interval = CMTimeMake(1, 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
            self?.currentTimeLabel.text = time.toDisplayString()
            let durationTime = self?.player.currentItem?.duration
            self?.durationLabel.text = durationTime?.toDisplayString()
            self?.setupLockscreenCurrentTime()
            self?.updateCurrentTimeSlider()
        }
    }
    
    fileprivate func setupLockscreenCurrentTime() {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        
        guard let currentItem = player.currentItem else { return }
        let durationInSeconds = CMTimeGetSeconds(currentItem.duration)
        let elapsedTimeInSeconds = CMTimeGetSeconds(player.currentTime())
        
        nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationInSeconds
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTimeInSeconds
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func updateCurrentTimeSlider() {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(1, 1))
        let percentage = currentTimeSeconds / durationSeconds
        currentTimeSlider.value = Float(percentage)
    }
    
    @objc func handleTapMaximize() {
        UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: nil)
    }
    
    // MARK: - Pan Gestures
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            handlePanChanged(gesture: gesture)
        } else if gesture.state == .ended {
            handlePanEnded(gesture: gesture)
        }
    }
    
    fileprivate func handlePanChanged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        self.miniPlayerView.alpha = 1 + translation.y / 200
        self.maximizedStackView.alpha = -translation.y / 200
    }
    
    fileprivate func handlePanEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.transform = .identity
            if translation.y < -200 || velocity.y < -500 {
                UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: nil)
            } else {
                self.miniPlayerView.alpha = 1
                self.maximizedStackView.alpha = 0
            }
        })
    }
    
    @objc fileprivate func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .changed {
            let translation = gesture.translation(in: superview)
            maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        } else if gesture.state == .ended {
            let translation = gesture.translation(in: superview)
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.maximizedStackView.transform = .identity
                
                if translation.y > 50 {
                    UIApplication.mainTabBarController()?.minimizePlayerDetails()
                }
            })
        }
    }
}
