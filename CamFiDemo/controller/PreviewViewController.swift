//
//  PreviewViewController.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 10/9/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation
import UIKit

class PreviewViewController: UIViewController {
    let api = ShootProof()
    let camera = CameraImages()
    @IBOutlet var image1: UIImageView?
    @IBOutlet var image2: UIImageView?
    @IBOutlet var sendSMS: UIButton?
    var images: [UIImage?]? = nil

    override func viewDidAppear(_ animated: Bool) {
        camera.last(n: 2) { (images) in
            self.images = images

            DispatchQueue.main.async {
                self.refreshView()
            }
            
            DispatchQueue.global().async {
                self.uploadPhotos(phoneNumber: "+14086633063", eventId: "3319335")
            }
        }
    }

    func refreshView() {
        guard let images = images, images.count >= 2 else { return }

        if let img1 = images[0], let img2 = images[1] {
            image1?.image = img1
            image2?.image = img2
        }
    }

    func uploadPhotos(phoneNumber: String, eventId: String) {
        guard let images = images, images.count >= 2 else { return }
        guard let img1 = images[0], let img2 = images[1] else { return }

        self.api.uploadPhoto(photo: img1, eventId: eventId, phoneNumber: phoneNumber)
        self.api.uploadPhoto(photo: img2, eventId: eventId, phoneNumber: phoneNumber)

    }

  @IBAction func tappedSendButton(sender: UIButton) {
        print("Tapped button")
        
        // Use your own details here
        let twilioSID = "ACedf09758de551ea53b70cc71cf41b19a"
        let twilioSecret = "860280cddb0f86ce5d165227c50b08b4"
        let fromNumber = "+14152129285"
        let toNumber = "+14086633063"
        let message = "Hey"
        
        // Build the request
        let request = NSMutableURLRequest(url: NSURL(string:"https://\(twilioSID):\(twilioSecret)@api.twilio.com/2010-04-01/Accounts/\(twilioSID)/SMS/Messages")! as URL)
        request.httpMethod = "POST"
        request.httpBody = "From=\(fromNumber)&To=\(toNumber)&Body=\(message)".data(using: String.Encoding.utf8)
        
        // Build the completion block and send the request
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            print("Finished")
            if let data = data, let responseDetails = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                // Success
                print("Response: \(responseDetails)")
            } else {
                // Failure
                print("Error: \(error)")
            }
        }).resume()
    }

}
