//
//  ShootProof.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 10/12/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation

class ShootProof {
    let url = URL(string: "https://api.shootproof.com/v2")!
    let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    convenience init() {
        self.init(accessToken: "ddbc353912ccf6b1dadbeea60da166987e3a9735")
    }
    
    func viewUrl(eventId: String, albumId: String) -> String {
        return "https://iconicbooth.shootproof.com/gallery/\(eventId)/album/\(albumId)"
    }

    typealias DidUploadPhoto = (_ error: Error?) -> ()
    
    func uploadPhoto(photo: UIImage, eventId: String, phoneNumber: String, whenDone: @escaping DidUploadPhoto) {
        let request = createRequest(eventId: eventId, albumId: phoneNumber, image: photo)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                // handle error here
                print(error)

                whenDone(error)
            }

            // if response was JSON, then parse it
            
            do {
                if let responseDictionary = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                    print("success == \(responseDictionary)")

                    whenDone(nil)
                    // note, if you want to update the UI, make sure to dispatch that to the main queue, e.g.:
                    //
                    // dispatch_async(dispatch_get_main_queue()) {
                    //     // update your UI and model objects here
                    // }
                }
            } catch let error {
                print(error)

                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("responseString = \(responseString)")
                
                whenDone(error)
            }
        }
        
        task.resume()
    }

    // https://api.shootproof.com/v2?method=sp.event.create&access_token=ddbc353912ccf6b1dadbeea60da166987e3a9735&event_name=TestFlow
    func createEvent(name: String) {
        let params: [String:String] = [
            "access_token": self.accessToken,
            "method": "sp.event.create",
            "event_name": name
        ]

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = params.map { (key, value) in
            return URLQueryItem(name: key, value: value)
        }
        
        if let url = components?.url {
            let request = URLRequest(url: url as URL)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                
            })
            
            task.resume()
        }
    }

    typealias DidGetAlbum = (_ albumId: String?, _ error: Error?) -> ()

    // https://api.shootproof.com/v2?access_token=ddbc353912ccf6b1dadbeea60da166987e3a9735&event_id=3319727&method=sp.album.get_list
    func findAlbum(name: String, eventId: String, whenDone: @escaping DidGetAlbum) {
        let url = makeURL(method: "sp.album.get_list", extraParameters: [
            "event_id": eventId
            ])
        
        let request = URLRequest(url: url)
        sendRequest(request: request) { (dict, error) in
            guard let albums = dict?["albums"] as? [[String:AnyObject]] else {
                // error
                return
            }

            let matchingAlbum = albums.first { name == ($0["name"] as! String) }

            if let album = matchingAlbum {
                whenDone(album["id"] as? String, nil)
            }
            else {
                whenDone(nil, nil)
            }
        }
    }

    func createAlbum(name: String, eventId: String, whenDone: @escaping DidGetAlbum) {
        let url = makeURL(method: "sp.album.create", extraParameters: [
            "event_id": eventId,
            "album_name": name
        ])

        let request = URLRequest(url: url)
        sendRequest(request: request) { (dict, error) in
            guard error == nil, let dict = dict else {
                // error
                return
            }

            if let id = dict["album"]?["id"] as? String {
                whenDone(id, nil)
            }
            else {
                // error
            }
        }
    }

    func findOrCreateAlbum(name: String, eventId: String, whenDone: @escaping DidGetAlbum) {
        findAlbum(name: name, eventId: eventId) { (albumId, error) in
            if let albumId = albumId {
                whenDone(albumId, nil)
            }
            else {
                self.createAlbum(name: name, eventId: eventId, whenDone: whenDone)
            }
        }
    }
    
    typealias RequestCompleted = (_ response: [String:AnyObject]?, _ error: Error?) -> ()

    func sendRequest(request: URLRequest, whenCompleted: @escaping RequestCompleted) {
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                return whenCompleted(nil, error)
            }
            
            if let data = data, let response = response as? HTTPURLResponse {
                guard response.statusCode == 200 else {
                    // error
                    return
                }

                do {
                    let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]

                    whenCompleted(dict, nil)
                }
                catch let error {
                    // error
                }
            }
        })
        
        task.resume()
    }

    func makeURL(method: String, extraParameters: [String: String]) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        let baseParameters: [String: String] = [
            "method": method,
            "access_token": self.accessToken
        ]

        var allParameters = baseParameters
        for (key, value) in extraParameters {
            allParameters[key] = value
        }

        var queryItems: [URLQueryItem] = []
        for (key, value) in allParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        components.queryItems = queryItems

        return components.url!
    }

    func makeURL(method: String) -> URL {
        return makeURL(method: method, extraParameters: [:])
    }

    // MARK: Private
    
    // http://stackoverflow.com/questions/26162616/upload-image-with-parameters-in-swift
    
    /// Create request
    ///
    /// - parameter userid:   The userid to be passed to web service
    /// - parameter password: The password to be passed to web service
    /// - parameter email:    The email address to be passed to web service
    ///
    /// - returns:            The NSURLRequest that was created
    
    func createRequest(eventId: String, albumId: String, image: UIImage) -> URLRequest {
        let params = [
            "event_id": eventId,
            "album_id": albumId,
            "watermark_id": "no"
        ]
        
        let boundary = generateBoundaryString()

        var request = URLRequest(url: makeURL(method: "sp.photo.upload"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBodyWithParameters(
            parameters: params,
            imageKey: "photo",
            image: image,
            boundary: boundary
        ) as Data
        
        return request
    }
    
    /// Create body of the multipart/form-data request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns:                The NSData of the body of the request
    
    func createBodyWithParameters(parameters: [String: String]?, imageKey: String, image: UIImage, boundary: String) -> NSData {
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }

        let pngData = UIImageJPEGRepresentation(image, 0.3)
        let mimetype = "image/jpg"

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(imageKey)\"; filename=photo.png\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(pngData!)
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(_ string: String) {
        let data = string.data(using: .utf8)
        append(data!)
    }
}
