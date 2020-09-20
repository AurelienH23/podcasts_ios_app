//
//  UserDefaults.swift
//  Podcast
//
//  Created by Aurélien Haie on 16/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    static let favoritedPodcastKey = "favoritedPodcastKey"
    static let downloadedEpisodeKey = "downloadedEpisodeKey"
    
    func savedPodcasts() -> [Podcast] {
        guard let savedPodcastsData = UserDefaults.standard.data(forKey: UserDefaults.favoritedPodcastKey) else { return [] }
        guard let savedPodcasts = NSKeyedUnarchiver.unarchiveObject(with: savedPodcastsData) as? [Podcast] else { return [] }
        return savedPodcasts
    }
    
    func downloadEpisode(episode: Episode) {
        do {
            var episodes = downloadedEpisodes()
            episodes.insert(episode, at: 0)
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodeKey)
        } catch let encodeErr {
            print("Failed to encode episode:", encodeErr)
        }
    }
    
    func deleteEpisode(at index: Int) {
        do {
            var episodes = downloadedEpisodes()
            episodes.remove(at: index)
            let data = try JSONEncoder().encode(episodes)
            UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodeKey)
        } catch let encodeErr {
            print("Failed to encode episode:", encodeErr)
        }
    }
    
    func downloadedEpisodes() -> [Episode] {
        guard let episodesData = UserDefaults.standard.data(forKey: UserDefaults.downloadedEpisodeKey) else { return [] }
        
        do {
            let episodes = try JSONDecoder().decode([Episode].self, from: episodesData)
            return episodes
        } catch let decodeErr {
            print("Failed to decode episodes:", decodeErr)
        }
        
        return []
    }
}
