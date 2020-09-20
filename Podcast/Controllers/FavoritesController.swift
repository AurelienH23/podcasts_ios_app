//
//  FavoritesController.swift
//  Podcast
//
//  Created by Aurélien Haie on 16/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit

class FavoritesController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    fileprivate let cellId = "cellId"
    var podcasts = UserDefaults.standard.savedPodcasts()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        podcasts = UserDefaults.standard.savedPodcasts()
        collectionView?.reloadData()
        UIApplication.mainTabBarController()?.viewControllers?.first?.tabBarItem.badgeValue = nil
    }
    
    // MARK: - Custom funcs
    
    fileprivate func setupCollectionView() {
        collectionView?.backgroundColor = .white
        collectionView?.register(FavoritePodcastCell.self, forCellWithReuseIdentifier: cellId)
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        collectionView?.addGestureRecognizer(gesture)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        print("Captured long press")
        let location = gesture.location(in: collectionView)
        
        guard let selectedIndexPath = collectionView?.indexPathForItem(at: location) else { return }
        
        print(selectedIndexPath.item)
        
        let alertController = UIAlertController(title: "Remove Podcast?", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
            self.podcasts.remove(at: selectedIndexPath.item)
            
            self.collectionView?.deleteItems(at: [selectedIndexPath])
            
            var listOfPodcasts = UserDefaults.standard.savedPodcasts()
            listOfPodcasts.remove(at: selectedIndexPath.item)
            let data = NSKeyedArchiver.archivedData(withRootObject: listOfPodcasts)
            UserDefaults.standard.set(data, forKey: UserDefaults.favoritedPodcastKey)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    // MARK: - UICollectionView
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! FavoritePodcastCell
        cell.podcast = podcasts[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 3 * 16) / 2
        return CGSize(width: width, height: width + 46)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let episodesController = EpisodesController()
        episodesController.podcast = podcasts[indexPath.item]
        navigationController?.pushViewController(episodesController, animated: true)
    }
    
}
