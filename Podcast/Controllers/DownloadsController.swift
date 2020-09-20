//
//  DownloadsController.swift
//  Podcast
//
//  Created by Aurélien Haie on 17/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit

class DownloadsController: UITableViewController {
    
    // MARK: - Properties
    
    fileprivate let cellId = "cellId"
    
    var episodes = UserDefaults.standard.downloadedEpisodes()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        episodes = UserDefaults.standard.downloadedEpisodes()
        tableView.reloadData()
    }
    
    // MARK: - Custom funcs
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadProgress), name: .downloadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDownloadComplete), name: .downloadComplete, object: nil)
    }
    
    @objc fileprivate func handleDownloadProgress(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let progress = userInfo["progress"] as? Double else { return }
        guard let title = userInfo["title"] as? String else { return }
        print(progress, title)
        guard let index = episodes.index(where: { $0.title == title }) else { return }
        guard let episodeCell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? EpisodeCell else { return }
        episodeCell.progressLabel.text = "\(Int(progress * 100))%"
        episodeCell.progressLabel.isHidden = false
        
        if progress == 1 {
            episodeCell.progressLabel.isHidden = true
        }
    }
    
    @objc fileprivate func handleDownloadComplete(notification: Notification) {
        guard let episodeDownloadComplete = notification.object as? APIService.EpisodeDownloadCompleteTuple else { return }
        guard let index = episodes.index(where: { $0.title == episodeDownloadComplete.episodeTitle }) else { return }
        episodes[index].fileUrl = episodeDownloadComplete.fileUrl
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as! EpisodeCell
        cell.episode = episodes[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 134
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .destructive, title: "Delete") { (_, _) in
            print("Deleting download")
            self.episodes.remove(at: indexPath.row)
            UserDefaults.standard.deleteEpisode(at: indexPath.row)
            self.tableView.reloadData()
        }
        return [editAction]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        if episode.fileUrl != nil {
            UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: episodes)
        } else {
            let alertController = UIAlertController(title: "File URL not found", message: "Cannot find local file, play using stream url instead", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                UIApplication.mainTabBarController()?.maximizePlayerDetails(episode: episode, playlistEpisodes: self.episodes)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            present(alertController, animated: true)
        }
        
    }
}
