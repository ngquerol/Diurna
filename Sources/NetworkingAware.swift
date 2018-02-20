//
//  NetworkingAware.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 11/11/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

protocol NetworkingAware {}

extension NetworkingAware {

    var apiClient: HackerNewsAPIClient {
        return FirebaseAPIClient.sharedInstance
    }
}
