//
//  PhotoInfo.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

struct PhotoInfo: Codable {
    var format: String
    var width: Int
    var height: Int
    var filename: String
    var id: Int
    var author: String
    var author_url: String
    var post_url: String
}
