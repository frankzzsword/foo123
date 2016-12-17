//
//  ThankYouViewController.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 10/20/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation
import UIKit

class ThankYouViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.performSegue(withIdentifier: "Exit", sender: self)
        }
    }
    
  
    }

