//
//  SearchResults.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Foundation

struct SearchResults: Decodable {
    let resultCount: Int
    let results: [Podcast]
}
