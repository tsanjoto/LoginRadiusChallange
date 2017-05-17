//
//  AlertUtils.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-09.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation
import UIKit

class AlertUtils
{
    
    /// Creates a simple alert box on top of given view controller
    class func showAlert(_ vc:UIViewController, title:String = "ALERT", message:String = "", completion:((UIAlertAction) -> Void)?)
    {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:completion))
            vc.present(alert, animated: true, completion:nil)
        }

    }
}
