//
//  PodcastCell.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit
import SDWebImage

class PodcastCell: UITableViewCell {
    
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var episodeCountLabel: UILabel!
    
    var podcast: Podcast! {
        didSet {
            trackNameLabel.text = podcast.trackName
            artistNameLabel.text = podcast.artistName
            
            episodeCountLabel.text = "\(podcast.trackCount ?? 0) Episodes"
            
            let url = URL(string: podcast.artworkUrl600 ?? "")
            podcastImageView.sd_setImage(with: url, completed: nil)
        }
    }
}
