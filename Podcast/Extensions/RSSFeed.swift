//
//  RSSFeed.swift
//  Podcast
//
//  Created by Aurélien Haie on 09/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import FeedKit

extension RSSFeed {
    func toEpisodes() -> [Episode] {
        let imageUrl = iTunes?.iTunesImage?.attributes?.href
        
        var episodes = [Episode]()
        
        items?.forEach({ (feedItem) in
            var episode = Episode(feedItem: feedItem)
            if episode.imageUrl == nil {
                episode.imageUrl = imageUrl
            }
            episodes.append(episode)
        })
        
        return episodes
    }
}
