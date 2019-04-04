//
//  PhotoDetailsViewController.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit
import Alamofire

class PhotoDetailsViewController: BackgroundViewController {
    @IBOutlet var photoView: UIImageView!
    @IBOutlet var author: UIButton!
    @IBOutlet var post: UIButton!
    @IBOutlet var photoDetails: UIView!
    
    var photo: PhotoInfo?
    var request: DataRequest?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        request = DataRequest.image(id: photo?.id, size: photo.map{ CGSize(width: $0.width, height: $0.height) } ?? photoView.bounds.size).responseImage(completionHandler: { [weak self] (image) in
            self?.photoView.image = image
        })
        author.setTitle(photo?.author, for: .normal)
        photoDetails.isHidden = photo == nil
    }
    
    deinit {
        request?.cancel()
    }
    
    // MARK: - Actions
    
    @IBAction func onAuthor(_ sender: UIButton) { }
    
    @IBAction func onPost(_ sender: UIButton) { }
}
