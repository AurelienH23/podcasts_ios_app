//
//  Podcast.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Foundation

class Podcast: NSObject, Decodable, NSCoding {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackName ?? "", forKey: "trackNameKey")
        aCoder.encode(artistName ?? "", forKey: "artistNameKey")
        aCoder.encode(artworkUrl600 ?? "", forKey: "artworkKey")
        aCoder.encode(feedUrl ?? "", forKey: "feedUrlKey")
    }
    
    required init?(coder aDecoder: NSCoder) {
        trackName = aDecoder.decodeObject(forKey: "trackNameKey") as? String
        artistName = aDecoder.decodeObject(forKey: "artistNameKey") as? String
        artworkUrl600 = aDecoder.decodeObject(forKey: "artworkKey") as? String
        feedUrl = aDecoder.decodeObject(forKey: "feedUrlKey") as? String
    }
    
    var trackName: String?
    var artistName: String?
    var artworkUrl600: String?
    var trackCount: Int?
    var feedUrl: String?
}
