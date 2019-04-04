//
//  PhotoCollectionViewCell.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit
import Alamofire

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var photoView: UIImageView!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var request: DataRequest?
    
    var photoInfo: PhotoInfo! {
        didSet {
            authorLabel.text = photoInfo.author
            activityIndicator.startAnimating()
            request = DataRequest.image(id: photoInfo.id, size: photoView.bounds.size).responseImage(completionHandler: { [weak self] image in
                self?.photoView.image = image
                self?.activityIndicator.stopAnimating()
            })
        }
    }
    
    override func prepareForReuse() {
        request?.cancel()
        photoView.image = nil
    }
}
