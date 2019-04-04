//
//  PhotosCollectionViewController.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit
import Alamofire

protocol PhotosCollectionViewControllerDelegate: AnyObject {
    func photosController(_ photosController: PhotosCollectionViewController, didSelectPhoto photo: PhotoInfo)
}

class PhotosCollectionViewController: UICollectionViewController {
    weak var delegate: PhotosCollectionViewControllerDelegate?
    var request: DataRequest?
    var photos: [PhotoInfo] = [] {
        didSet { collectionView.reloadData() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        request = DataRequest.photosList().response(completionHandler: { [weak self] (reponse: [PhotoInfo]) in
            self?.photos = reponse
        })
    }
    
    // MARK: - Collection View Delegate

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCollectionViewCell
        cell.photoInfo = photos[indexPath.item]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.photosController(self, didSelectPhoto: photos[indexPath.item])
    }
}
