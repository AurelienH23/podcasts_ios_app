//
//  PodcastsSearchController.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Alamofire
import UIKit

class PodcastsSearchController: UITableViewController, UISearchBarDelegate {
    
    // MARK: - Properties
    
    let cellId = "cellId"
    var podcasts = [Podcast]()
    
    let searchController = UISearchController(searchResultsController: nil)
    var timer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupSearchBar()
        
        searchBar(searchController.searchBar, textDidChange: "Voong")
    }
    
    // MARK: - Custom funcs
    
    fileprivate func setupTableView() {
        tableView.tableFooterView = UIView()
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
    }
    
    fileprivate func setupSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        definesPresentationContext = true
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
        let podcast = podcasts[indexPath.row]
        cell.podcast = podcast
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = "Please enter a search term"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .purple
        return label
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 132
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return podcasts.count > 0 ? 0 : 250
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodesController = EpisodesController()
        let podcast = podcasts[indexPath.row]
        episodesController.podcast = podcast
        navigationController?.pushViewController(episodesController, animated: true)
    }
    
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
            APIService.shared.fetchPodcasts(for: searchText) { (podcasts) in
                self.podcasts = podcasts
                self.tableView.reloadData()
            }
        })
    }
}
