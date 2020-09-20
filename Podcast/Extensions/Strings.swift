//
//  Strings.swift
//  Podcast
//
//  Created by Aurélien Haie on 09/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Foundation

extension String {
    func toSecureHTTPS() -> String {
        return self.contains("https") ? self : self.replacingOccurrences(of: "http", with: "https")
    }
}
