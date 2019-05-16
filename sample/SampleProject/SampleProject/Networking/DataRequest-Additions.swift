//
//  DataRequest-Additions.swift
//  SampleProject
//
//  Created by radu.costea on 4/4/19.
//  Copyright © 2019 Softvision. All rights reserved.
//

import Alamofire

extension DataRequest {
    public func response<T: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (T) -> Void) -> Self {
        return responseData() { (response) in
            guard let data = response.data else { return }
            do {
                let decoder = JSONDecoder()
                let obj = try decoder.decode(T.self, from: data)
                completionHandler(obj)
            } catch { }
        }
    }
    
    public func responseImage(queue: DispatchQueue? = nil, completionHandler: @escaping (UIImage) -> Void) -> Self {
        return responseData(completionHandler: { (response) in
            guard let data = response.data, let image = UIImage(data: data) else { return }
            completionHandler(image)
        })
    }
}

extension DataRequest {
    static func photosList() -> DataRequest {
        return Alamofire.request("https://picsum.photos/list")
    }
    
    static func image(id: Int? = nil, grayscale: Bool = false, blured: Bool = false, size: CGSize) -> DataRequest {
        let blur: String? = blured ? "blur" : nil
        let imageId: String? = id.map{ "image=\($0)" } ?? "random"
        let gray: String? = grayscale ? "g" : nil
        let size: String? = "\(Int(size.width))/\(Int(size.height))"
        let root: String? = "https://picsum.photos"
        
        let path = [root, gray, size].compactMap{ $0 }.joined(separator: "/")
        let arguments = [imageId, blur].compactMap{ $0 }.joined(separator: "&")
        
        return Alamofire.request([path, arguments].joined(separator: "?"))
    }
    
}
