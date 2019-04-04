//
//  ViewController.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import UIKit
import WebKit

class WebViewContainer: BackgroundViewController {
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var webView: WKWebView!
    var path: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.embedWebView()
        
        if let path = path, let url = URL(string: path) {
            let request = URLRequest(url: url)
            view.bringSubviewToFront(activityIndicator)
            activityIndicator.startAnimating()
            webView.load(request)
            webView.isHidden = true
        }
    }
    
    private func embedWebView() {
        let webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
        ])
        self.webView = webView
    }
}

extension WebViewContainer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        webView.isHidden = false
    }
}
