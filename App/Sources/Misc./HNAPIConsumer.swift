//
//  HNAPIConsumer.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 30/06/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import HackerNewsAPI
import Firebase

let app = FirebaseApp.app(),
    client = FirebaseHNAPIClient(app: app!)

protocol HNAPIConsumer {
    var apiClient: HNAPIClient { get }
}

extension HNAPIConsumer {
    var apiClient: HNAPIClient { client }
}
