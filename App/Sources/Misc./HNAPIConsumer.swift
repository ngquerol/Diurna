//
//  HNAPIConsumer.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 30/06/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import Firebase
import HackerNewsAPI

// MARK: - API

private let api: HNAPIClient = {
    FirebaseApp.configure()

    guard let app = FirebaseApp.app() else {
        fatalError("Failed to initialize Firebase application")
    }

    return FirebaseHNAPIClient(app: app)
}()

protocol HNAPIConsumer {
    var apiClient: HNAPIClient { get }
}

extension HNAPIConsumer {
    var apiClient: HNAPIClient { api }
}

// MARK: - Web

private let web: HNWebClient = HTTPHNWebClient()

protocol HNWebConsumer {
    var webClient: HNWebClient { get }
}

extension HNWebConsumer {
    var webClient: HNWebClient { web }
}
