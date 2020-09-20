//
//  EpisodesController.swift
//  Podcast
//
//  Created by Aurélien Haie on 08/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import FeedKit
import UIKit

class EpisodesController: UITableViewController {
    
    // MARK: Properties
    
    fileprivate let cellId = "cellId"
    fileprivate let favoritedPodcastKey = "favoritedPodcastKey"
    
    var podcast: Podcast! {
        didSet {
            navigationItem.title = podcast.trackName
            
            fetchEpisodes()
        }
    }
    
    var episodes = [Episode]()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        setupNavigationBarButtons()
    }
    
    // MARK: Custom funcs
    
    fileprivate func setupNavigationBarButtons() {
        let savedPodcasts = UserDefaults.standard.savedPodcasts()
        
        if savedPodcasts.contains(podcast) {
            print("SAVED")
        }
        
        let hasFavorited = savedPodcasts.index(where: { $0.trackName == self.podcast?.trackName && $0.artistName == self.podcast?.artistName }) != nil
        if hasFavorited {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "heart"), style: .plain, target: nil, action: nil)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Favorite", style: .plain, target: self, action: #selector(handleSaveFavorite))
        }
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
    }
    
    func fetchEpisodes() {
        guard let feedUrl = podcast.feedUrl else { return }
        APIService.shared.fetchEpisodes(feedUrl: feedUrl) { (episodes) in
            self.episodes = episodes
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    @objc fileprivate func handleSaveFavorite() {
        guard let podcast = podcast else { return }
        var listOfPodcasts = UserDefaults.standard.savedPodcasts()
        listOfPodcasts.append(podcast)
        let data = NSKeyedArchiver.archivedData(withRootObject: listOfPodcasts)
        UserDefaults.standard.set(data, forKey: UserDefaults.favoritedPodcastKey)
        showBadgeHighlight()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "heart"), style: .plain, target: nil, action: nil)
    }
    
    fileprivate func showBadgeHighlight() {
        UIApplication.mainTabBarController()?.viewControllers?.first?.tabBarItem.badgeValue = "New"
    }
    
    @objc fileprivate func handleFetchSavedFavorite() {
        guard let data = UserDefaults.standard.data(forKey: UserDefaults.favoritedPodcastKey) else { return }
        let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Podcast]
        savedPodcasts?.forEach({ (p) in
            print(p.trackName)
        })
        
    }
    
    // MARK: UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.item]
        cell.episode = episode
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 132
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: episodes)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.color = .darkGray
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return episodes.isEmpty ? 200 : 0
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let downloadAction = UITableViewRowAction(style: .normal, title: "Download") { (_, _) in
            let episode = self.episodes[indexPath.row]
            UserDefaults.standard.downloadEpisode(episode: episode)
            
            APIService.shared.downloadEpisode(episode: episode)
        }
        return [downloadAction]
    }
}
