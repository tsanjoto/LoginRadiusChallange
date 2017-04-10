//
//  DetailViewController.swift
//  SwiftDemo
//
//  Created by Raviteja Ghanta on 19/05/16.
//  Copyright © 2016 Raviteja Ghanta. All rights reserved.
//

import Eureka
import SwiftyJSON
import LoginRadiusSDK

class DetailViewController: FormViewController {
    
    //List of countries provided from Apple's NSLocale class
    let countries = NSLocale.isoCountryCodes.map { (code:String) -> String in
        let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
        return NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Extract relevant data for simple profile
        let defaults = UserDefaults.standard
        let userProfileStr = defaults.object(forKey: "lrUserProfile") as! String //LR had a huge chunk on converting to proper nsdictionary, skip save as string
        let user = JSON.parse(string: userProfileStr)

        let userEmail = ((user["Email"].array)?[0]["Value"] )?.string
        
        var userCountry:String? = nil
        if let countryDict = user["Country"].dictionary,
            let countryStr = countryDict["Name"]?.string
        {
            userCountry = countryStr
        }

        let gender = Gender(string: user["Gender"].string ) ?? .unknown
        //end data extraction
        
        //Small UI modification
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.title = "User Profile"
        
        //Form setup
        self.form = Form()
        
        form  +++ Section("")
            <<< ButtonRow("Log out")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.logoutPressed()
            }
        form  +++ Section("")
            <<< ButtonRow("View Full Profile")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.showFullProfileController()
            }
        form  +++ Section("")
            <<< NameRow("FirstName")
            {
                $0.title = "First Name"
                $0.value = user[$0.tag!].stringValue
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnDemand
                }.onRowValidationChanged { cell, row in
                    self.toggleRedBorderShowErrorMessage(cell: cell, row: row)
            }
            <<< NameRow("LastName")
            {
                $0.title = "Last Name"
                $0.value = user[$0.tag!].stringValue
                $0.add(rule: RuleRequired())
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnDemand
                }.onRowValidationChanged { cell, row in
                    self.toggleRedBorderShowErrorMessage(cell: cell, row: row)

            }
            <<< EmailRow("Email")
            {
                $0.title = $0.tag
                $0.value = userEmail ?? nil
                $0.disabled = Condition(booleanLiteral: true)
            }
            <<< SegmentedRow<String>("Gender"){
                $0.title = $0.tag
                $0.options = Gender.allPossibleGendersSymbols
                $0.add(rule: RuleRequired())
                $0.value = gender.symbol
            }
        
            <<< PushRow<String>("Country") {
                $0.title = $0.tag
                $0.options = countries
                $0.value = userCountry
                $0.selectorTitle = "Country"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnDemand
                }.onRowValidationChanged { cell, row in
                    self.toggleRedBorderShowErrorMessage(cell: cell, row: row)
            }

        form  +++ Section("")
        <<< ButtonRow("Update Profile")
        {
            $0.title = $0.tag
            }.onCellSelection{ row in
                self.validateInput()
        }
        

    }
    
    /// Validates simple profile input, see the form construction for form rules
    func validateInput()
    {
        let errors:[ValidationError] = self.form.validate()
        
        if errors.count == 0
        {
            updateProfile()
        }
    }
    
    /// Parse input into Dictionaries and send to server
    func updateProfile()
    {

        var parameters:[String:Any] = [:]
        
        for row in form.allRows
        {
            if row.tag != "Email"
            {
                parameters[row.tag!] = row.baseValue
            }
        }
        
        let convertGenderBack = Gender(string: parameters["Gender"] as! String? )
        parameters["Gender"] = convertGenderBack!.rawValue
        
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "lrAccessToken") as! String
        
        let queryParam = [  "appkey": AppDelegate.apiKey,
                           "appsecret": AppDelegate.apiSecret,
                           "token": token
        ]
        
        let url = LoginRadiusUrlMethods.base + LoginRadiusUrlMethods.updateUserProfile
        
        NetworkUtils.restCall(url , method: .POST, queryParam:queryParam, parameters: parameters, completion: {
            (response)->Void in
            
            if let err = response.error
            {
                print(err.description)
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
            }else
            {
                AlertUtils.showAlert(self, title: "Success", message: "User updated!", completion: {(alert)->Void in
                    self.logoutPressed()
                })
            }
            
        })
        
    }
    
    func showResponse(title:String, message:String, completion:((UIAlertAction) -> Void)?)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:completion))
        self.present(alert, animated: true, completion:nil)
    }
    
    fileprivate func showFullProfileController () {
        self.performSegue(withIdentifier: "full profile", sender: self);
    }
    
    fileprivate func logoutPressed() {
        LoginRadiusSDK.logout()
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func toggleRedBorderShowErrorMessage(cell:UIView, row:BaseRow)
    {
        if !row.isValid {
            cell.layer.borderWidth = 3
            cell.layer.borderColor = UIColor.red.cgColor
        }else{
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
