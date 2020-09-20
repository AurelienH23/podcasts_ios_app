//
//  UIApplication.swift
//  Podcast
//
//  Created by Aurélien Haie on 12/04/2018.
//  Copyright © 2018 Aurélien Haie. All rights reserved.
//

import UIKit

extension UIApplication {
    static func mainTabBarController() -> MainTabBarController? {
        return shared.keyWindow?.rootViewController as? MainTabBarController
    }
}
