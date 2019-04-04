//
//  MenuViewController.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit
import Alamofire

class MenuViewController: BackgroundViewController {
    // MARK: - Actions

    @IBAction func onShowGallery(_ sender: UIButton) {
        self.go(to: .showPhotos)
    }
    
    @IBAction func onRandomPhoto(_ sender: UIButton) {
        self.go(to: .showRandom)
    }
    
    // MARK: - Navigation
    
    func prepare(forRoute route: Routes, destination: GalleryViewController) { }
    
    func prepare(forRoute route: Routes, destination: PhotoDetailsViewController) {
        destination.photo = nil
    }
}
