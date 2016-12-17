//
//  StartViewController.swift
//  CamFiDemo
//
//  Created by Varun Mishra on 10/20/16.
//  Copyright © 2016 CamFi. All rights reserved.
//

import Foundation
import UIKit

class StartViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {

        return fromViewController is ThankYouViewController
    }

    @IBAction func unwindToBeginning(_ unwindSegue: UIStoryboardSegue) {
        print("unwinding")
    }
}
