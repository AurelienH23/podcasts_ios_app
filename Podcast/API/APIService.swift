//
//  APIService.swift
//  Podcast
//
//  Created by Aurélien Haie on 07/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import Alamofire
import Foundation
import FeedKit

extension Notification.Name {
    static let downloadProgress = NSNotification.Name("downloadProgress")
    static let downloadComplete = NSNotification.Name("downloadComplete")
}

class APIService {
    
    // MARK: - Singleton
    
    static let shared = APIService()
    
    // MARK: - Properties
    
    typealias EpisodeDownloadCompleteTuple = (fileUrl: String, episodeTitle: String)
    
    let baseiTunesUrl = "https://itunes.apple.com/search"
    
    // MARK: - Functions
    
    func fetchPodcasts(for searchText: String, completionHandler: @escaping ([Podcast]) -> ()) {
        
        let parameters = ["term":searchText, "media": "podcast"]
        
        Alamofire.request(baseiTunesUrl, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { (dataResponse) in
            if let err = dataResponse.error {
                print("Failed to contact google \(err)")
                return
            }
            
            guard let data = dataResponse.data else { return }
            
            do {
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                completionHandler(searchResult.results)
            } catch let decodeErr {
                print("Failed to decode result: \(decodeErr)")
            }
        }
    }
    
    func fetchEpisodes(feedUrl: String, completionHandler: @escaping ([Episode]) -> ()) {
        let securedFeedUrl = feedUrl.toSecureHTTPS()
        
        guard let url = URL(string: securedFeedUrl) else { return }
        
        DispatchQueue.global(qos: .background).async {
            let parser = FeedParser(URL: url)
        
            parser?.parseAsync(result: { (result) in
                if let err = result.error {
                    print("Failed to parse XML feed: \(err)")
                    return
                }
                
                guard let feed = result.rssFeed else { return }
                let episodes = feed.toEpisodes()
                completionHandler(episodes)
            })
        }
    }
    
    func downloadEpisode(episode: Episode) {
        let downloadRequest = DownloadRequest.suggestedDownloadDestination()
        Alamofire.download(episode.streamUrl, to: downloadRequest).downloadProgress { (progress) in
            NotificationCenter.default.post(name: .downloadProgress, object: nil, userInfo: ["title": episode.title, "progress": progress.fractionCompleted])
            }.response { (resp) in
                let episodeDownloadComplete = EpisodeDownloadCompleteTuple(resp.destinationURL?.absoluteString ?? "", episode.title)
                NotificationCenter.default.post(name: .downloadComplete, object: episodeDownloadComplete, userInfo: nil)
                var downloadedEpisodes = UserDefaults.standard.downloadedEpisodes()
                guard let index = downloadedEpisodes.index(where: { $0.title == episode.title && $0.author == episode.author }) else { return }
                downloadedEpisodes[index].fileUrl = resp.destinationURL?.absoluteString ?? ""
                
                do {
                    let data = try JSONEncoder().encode(downloadedEpisodes)
                    UserDefaults.standard.set(data, forKey: UserDefaults.downloadedEpisodeKey)
                } catch let err {
                    print("Failed to encode downloadedEpisodes: ", err)
                }
        }
    }
}
