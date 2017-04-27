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
    
    var urlMethods:Int = 1 //1 = v1. 2 = v2...
    
    //List of countries provided from Apple's NSLocale class
    let countries = NSLocale.isoCountryCodes.map { (code:String) -> String in
        let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
        return NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Extract relevant data for simple profile
        let defaults = UserDefaults.standard
        var user:JSON = JSON([])
        
        if let userProfileStr = defaults.object(forKey: "lrUserProfile") as? String //LR had a huge chunk on converting to proper nsdictionary, skip save as string
        {
            user = JSON.parse(string: userProfileStr)
        }else if let userDict = defaults.object(forKey: "lrUserProfile") as? NSDictionary
        {
            user = JSON(userDict)
        }

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
            switch urlMethods
            {
                case 2:
                    updateProfileV2()
                case 1:
                fallthrough
                default:
                    updateProfileV1()
            }
           // updateProfile()
        }
    }
    
    /// Parse input into Dictionaries and send to server
    func updateProfileV1()
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
        
        let url = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.updateUserProfile
        
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
    
    func updateProfileV2()
    {
        
        var parameters:[String:Any] = [:]
        
        for row in form.allRows
        {

            //v1's country is just a string, v2 is an object consist of code & name
            if row.tag == "Country"
            {
                //get me the code given the display name
                var code = ""
                if let i = countries.index(of: row.baseValue as! String)
                {
                    code = NSLocale.isoCountryCodes[i]
                }
                
                parameters[row.tag!] = ["Code":code,"Name":row.baseValue!]
                continue
            }
            
            if row.tag != "Email"
            {
                parameters[row.tag!] = row.baseValue
            }
            
        }
        
        let convertGenderBack = Gender(string: parameters["Gender"] as! String? )
        parameters["Gender"] = convertGenderBack!.rawValue
        
        let defaults = UserDefaults.standard
        let token = defaults.object(forKey: "lrAccessToken") as! String
        
        let queryParam = [  "apikey": AppDelegate.apiKey,
                            "access_token": token
        ]
        print(parameters)
        let url = LoginRadiusUrlMethodsV2.base + LoginRadiusUrlMethodsV2.updateUserProfile
        
        NetworkUtils.restCall(url , method: .PUT, queryParam:queryParam, parameters: parameters, completion: {
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
