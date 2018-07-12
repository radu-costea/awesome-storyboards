//
//  ViewController.swift
//  SampleProject
//
//  Created by radu.costea on 7/9/18.
//  Copyright © 2018 Softvision. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        go(to: .showNav22)
    }


}

extension ViewController {
    func prepare(forRoute route: ViewController.Routes, destination: UINavigationController) {
        // Error if not implemented

    }
}
