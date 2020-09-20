//
//  Episode.swift
//  Podcast
//
//  Created by Aurélien Haie on 09/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Foundation
import FeedKit

struct Episode: Codable {
    let title: String
    let pubDate: Date
    let description: String
    var imageUrl: String?
    let author: String
    let streamUrl: String
    var fileUrl: String?
    
    init(feedItem: RSSFeedItem) {
        self.title = feedItem.title ?? ""
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? ""
        self.imageUrl = feedItem.iTunes?.iTunesImage?.attributes?.href
        self.author = feedItem.iTunes?.iTunesAuthor ?? ""
        self.streamUrl = feedItem.enclosure?.attributes?.url ?? ""
    }
}
