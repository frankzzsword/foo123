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
    @IBOutlet weak var phoneNumberField: UITextField!
    
    var images: [UIImage?]? = nil

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        loadImages()
    }
    
    func loadImages() {
        camera.last(n: 2) { [weak self] (images) in
            self?.images = images
            
            DispatchQueue.main.async {
                self?.refreshView()
            }
        }
    }

    func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.keyboardType = UIKeyboardType.emailAddress
        self.animateViewMoving(up: true, moveValue: 50)
        
    }
    func textFieldDidEndEditing(textField: UITextField) {
        self.animateViewMoving(up: false, moveValue: 50)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat) {
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0,  dy: movement)
        UIView.commitAnimations()
    }
    
    func refreshView() {
        guard let images = images, images.count >= 2 else { return }

        if let img1 = images[0], let img2 = images[1] {
            image1?.image = img1
            image2?.image = img2
        }
    }
    
    typealias DidUploadPhotos = (_ error: Error?) -> ()

    func uploadPhotos(phoneNumber: String, eventId: String, whenDone: DidUploadPhotos) {
        guard let images = images, images.count >= 2 else { return }
        guard let img1 = images[0], let img2 = images[1] else { return }

        self.api.uploadPhoto(photo: img1, eventId: eventId, phoneNumber: phoneNumber) { (error) in
            // did upload
        }

        self.api.uploadPhoto(photo: img2, eventId: eventId, phoneNumber: phoneNumber) { (error) in
            // did upload
        }
    }

  @IBAction func tappedSendButton(sender: UIButton) {
        DispatchQueue.global().async {
            let eventId = "3337931"
            self.api.findOrCreateAlbum(name: self.phoneNumberField.text!, eventId: eventId, whenDone: { (albumId, error) in
                guard error == nil else {
                    // error
                    return
                }
                guard let albumId = albumId else {
                    // error
                    return
                }

                let url = self.api.viewUrl(eventId: eventId, albumId: albumId)

                // 1. send text message
                self.sendTextMessage(url: url)

                // 2. upload photos
                self.uploadPhotos(phoneNumber: albumId, eventId: eventId, whenDone: { (error) in
                    guard error == nil else {
                        // error
                        return
                    }

                    // done!
                    // ...
                })
            })
        }
    }
    
    func sendTextMessage(url: String) {
        print("Tapped button")
        
        // Use your own details here
        let twilioSID = "ACedf09758de551ea53b70cc71cf41b19a"
        let twilioSecret = "860280cddb0f86ce5d165227c50b08b4"
        let fromNumber = "+14152129285"
        let toNumber = "+1\(phoneNumberField.text!)"
        let message = "Your event photos are available at \(url)"
        
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
