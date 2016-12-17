//
//  AnimateViewController.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 12/17/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation

class AnimateViewController: UIViewController {
    @IBOutlet weak var birdTypeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup that your app requires
    }
    
    @IBAction func updateBirdTypeLabel(_ sender: UIButton) {
        // Fade out to set the text
        
        UIView.animate(withDuration: 0.6 ,
                                   animations: {
                                    self.birdTypeLabel.transform = CGAffineTransform(scaleX: 300, y: 300)
        },
                                   completion: { finish in
                                    UIView.animate(withDuration: 300){
                                        self.birdTypeLabel.transform = CGAffineTransform.identity
                                    }
        })
        
        }

}
