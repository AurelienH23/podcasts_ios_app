//
//  MainTabBarController.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    let playerDetailsView = PlayerDetailsView.initFromNib()
    var maximizedTopAnchorConstraint: NSLayoutConstraint!
    var minimizedTopAnchorConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.tintColor = .purple
        
        setupViewControllers()
        
        setupPlayerDetailView()
    }
    
    // MARK: - Custom funcs
    
    fileprivate func setupViewControllers() {
        viewControllers = [
            generateNavigationController(with: FavoritesController(collectionViewLayout: UICollectionViewFlowLayout()), title: "Favorites", image: #imageLiteral(resourceName: "favorites")),
            generateNavigationController(with: PodcastsSearchController(), title: "Search", image: #imageLiteral(resourceName: "search")),
            generateNavigationController(with: DownloadsController(), title: "Downloads", image: #imageLiteral(resourceName: "downloads"))
        ]
    }
    
    fileprivate func generateNavigationController(with rootViewController: UIViewController, title: String, image: UIImage) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.navigationBar.prefersLargeTitles = true
        navController.navigationBar.tintColor = .purple
        rootViewController.navigationItem.title = title
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        return navController
    }
    
    fileprivate func setupPlayerDetailView() {
        view.insertSubview(playerDetailsView, belowSubview: tabBar)
        
        playerDetailsView.translatesAutoresizingMaskIntoConstraints = false
        
        maximizedTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height)
        minimizedTopAnchorConstraint = playerDetailsView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -64)
        
        maximizedTopAnchorConstraint.isActive = true
        playerDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomAnchorConstraint = playerDetailsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.height)
        bottomAnchorConstraint.isActive = true
        playerDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }
    
    @objc func minimizePlayerDetails() {
        maximizedTopAnchorConstraint.isActive = false
        minimizedTopAnchorConstraint.isActive = true
        bottomAnchorConstraint.constant = view.frame.height - tabBar.frame.height
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.tabBar.transform = .identity
            self.playerDetailsView.maximizedStackView.alpha = 0
            self.playerDetailsView.miniPlayerView.alpha = 1
        })
    }
    
    func maximizePlayerDetails(episode: Episode?, playlistEpisodes: [Episode] = []) {
        minimizedTopAnchorConstraint.isActive = false
        maximizedTopAnchorConstraint.isActive = true
        maximizedTopAnchorConstraint.constant = 0
        bottomAnchorConstraint.constant = 0
        
        if episode != nil {
            playerDetailsView.episode = episode
        }
        
        playerDetailsView.playlistEpisodes = playlistEpisodes
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.tabBar.transform = CGAffineTransform(translationX: 0, y: 100)
            self.playerDetailsView.maximizedStackView.alpha = 1
            self.playerDetailsView.miniPlayerView.alpha = 0
        })
    }
}
