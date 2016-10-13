//
//  CameraImages.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 10/9/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation
import UIKit

class CameraImages {
    var imagePaths: [String]
    var images: [UIImage]

    var finishedLoading: Bool {
        didSet {
            guard finishedLoading == true else { return }
            guard let onLoad = onLoad, let n = lastCount else { return }

            last(n: n, onLoad: onLoad)
        }
    }
    var onLoad: (([UIImage?]) -> ())?
    var lastCount: Int?

    init() {
        self.imagePaths = []
        self.finishedLoading = false
        self.images = []

        NotificationCenter.default.addObserver(self, selector: #selector(CameraImages.didLoadImages(notification:)), name: NSNotification.Name(rawValue: MWPHOTO_LOADING_DID_END_NOTIFICATION), object: nil)

        loadImages(start: 0, count: 2)
    }
    
    @objc func didLoadImages(notification: NSNotification) {
        let photo = notification.object as! MWPhoto
        
        images.append(photo.underlyingImage)
        
        if images.count == 2 {
            onLoad!(images)
        }
    }

    func last(n: Int, onLoad: @escaping ([UIImage?]) -> ()) {
        if self.finishedLoading == false {
            self.lastCount = n
            self.onLoad = onLoad

            return
        }

        let lastImagePaths = imagePaths.prefix(n)
        let mediaItems = lastImagePaths.map { CameraMedia(path: $0) }
        let images = mediaItems.map { MWPhoto(url: $0!.mediaURL()) }

        let actualImages: [UIImage] = images.flatMap { media in
            guard let image = media?.underlyingImage else {
                media?.loadUnderlyingImageAndNotify()

                return nil
            }

            return image
        }

        // wait for load notification
        if actualImages.count != n { return }

        onLoad(actualImages)
    }

    func loadImages(start: UInt, count: UInt) {
        CamFiAPI.camFiGetImages(withOffset: start, count: count) { (error, imagePaths) in
            guard error == nil else { return }
            guard let imagePaths = imagePaths as? [String] else { return }

            self.imagePaths.append(contentsOf: imagePaths)
            self.finishedLoading = true
        }
    }
}
