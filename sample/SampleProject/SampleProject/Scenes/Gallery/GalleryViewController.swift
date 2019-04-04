//
//  GalleryViewController.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit

class GalleryViewController: BackgroundViewController {
    var photosController: PhotosCollectionViewController!
    var selectedPhoto: PhotoInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Navigation

    func prepare(forRoute route: GalleryViewController.Routes, destination: PhotosCollectionViewController) {
        photosController = destination
        photosController.delegate = self
    }
    
    func prepare(forRoute route: GalleryViewController.Routes, destination: PhotoDetailsViewController) {
        destination.photo = selectedPhoto
    }
}

extension GalleryViewController: PhotosCollectionViewControllerDelegate {
    func photosController(_ photosController: PhotosCollectionViewController, didSelectPhoto photo: PhotoInfo) {
        self.selectedPhoto = photo
        self.go(to: .showDetails)
    }
}
