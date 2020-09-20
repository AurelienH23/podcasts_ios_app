//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Aurélien Haie on 09/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit

class EpisodeCell: UITableViewCell {
    
    var episode: Episode! {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            pubDateLabel.text = dateFormatter.string(from: episode.pubDate)
            
            titleLabel.text = episode.title
            
            descriptionLabel.text = episode.description
            
            let url = URL(string: episode.imageUrl?.toSecureHTTPS() ?? "")
            episodeImageView.sd_setImage(with: url)
        }
    }
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
