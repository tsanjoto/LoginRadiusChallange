//
//  DetailViewController.swift
//  SwiftDemo
//
//  Created by Raviteja Ghanta on 19/05/16.
//  Copyright © 2016 Raviteja Ghanta. All rights reserved.
//

import Eureka
import SwiftyJSON

class FullDetailViewController: FormViewController {
    
    var dateFormatter:DateFormatter = {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormat
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        let userProfileStr = defaults.object(forKey: "lrUserProfile") as! String //LR had a huge chunk on converting to proper nsdictionary, skip save as string
        let user = JSON.parse(string: userProfileStr)
        self.form = Form()
        
        self.navigationItem.title = "Full Profile"
    
        form  +++ Section("")
        for (k,v) in user
        {
            addEurekaElement(key: k , userInfo: v)
        }
    }
    
    /// Add a eureka row element from a given key dictionary and a generic type value
    func addEurekaElement( key:String, userInfo: JSON )
    {
        var lastSection:Section = form.last!
        

            
        if let int =  userInfo.int
        {
        
            //print("\(key) is an Int")
            lastSection <<< IntRow(key)
            {
                $0.title = $0.tag
                $0.value = int
            }
        }else if let bool = userInfo.bool
        {
            //print("\(key) is a Bool")
            lastSection <<< SwitchRow(key)
            {
                $0.title = $0.tag
                $0.value = bool
            }
            
        }else if let str = userInfo.string
        {
            //print("\(key) is a String")
            if key.lowercased().contains("date")
            {
                lastSection <<< DateRow(key)
                {
                    $0.title = $0.tag
                    $0.value = dateFormatter.date(from: str)
                }
            }else if key.lowercased().contains("url"),
                let url = URL(string:str)
            {
                lastSection <<< URLRow(key)
                {
                    $0.title = $0.tag
                    $0.value = url
                }
            }else if key.lowercased().contains("email")
            {
                lastSection <<< EmailRow(key)
                {
                    $0.title = $0.tag
                    $0.value = str
                }
            }else if key.lowercased().contains("name")
            {
                lastSection <<< NameRow(key)
                {
                    $0.title = $0.tag
                    $0.value = str
                }
            }else if key.lowercased().contains("password")
            {
                lastSection <<< PasswordRow(key)
                {
                    $0.title = $0.tag
                    $0.value = str
                }
            }else
            {
                let disabled = Condition(booleanLiteral: (key.contains("Id") || key.contains("ID") || key.contains("Uid")))
                lastSection <<< TextRow(key)
                {
                    $0.title = $0.tag
                    $0.value = str
                    $0.disabled = disabled
                }
            }
            
        }else if let arr = userInfo.array
        {
            //print("\(key) is an Array")
            form  +++ Section(key)
            lastSection = form.last!
            
            //Handle email object and phone numbers manually
            if key == "Email"
            {
                for i in arr
                {
                    if let newDict = i.dictionaryObject
                    {
                        for (dictkey, dictv) in newDict
                        {
                            let k = dictkey 
                            let v = dictv as! String
                            
                            if k.contains("Value")
                            {
                                lastSection <<< EmailRow(k)
                                {
                                    $0.title = $0.tag
                                    $0.value = v
                                    $0.disabled = Condition(booleanLiteral: true)
                                    
                                }
                            }else if k.contains("Type")
                            {
                                lastSection <<< TextRow(k)
                                {
                                    $0.title = $0.tag
                                    $0.value = v
                                    $0.disabled = Condition(booleanLiteral: true)
                                }
                            }
                        }
                    }
                }
                
            }else if key == "PhoneNumbers"
            {
                for i in arr
                {
                    if let newDict = i.dictionaryObject
                    {
                        for (dictkey, dictv) in newDict
                        {
                            let k = dictkey as! String
                            let v = dictv as! String
                            
                            if k.contains("PhoneNumber")
                            {
                                lastSection <<< PhoneRow(k)
                                {
                                    $0.title = $0.tag
                                    $0.value = v
                                    
                                }
                            }else if k.contains("PhoneType")
                            {
                                lastSection <<< TextRow(k)
                                {
                                    $0.title = $0.tag
                                    $0.value = v
                                }
                            }
                        }
                    }
                }
            }
            
            form  +++ Section("")
            
        }else if let dict = userInfo.dictionary
        {
            //print("\(key) is a Dictionary")
            form  +++ Section(key)
            
            for (k,v) in dict
            {
                addEurekaElement(key: k , userInfo: v)
            }
            form  +++ Section("")
            
        }else{
            print("\(key), unknown type")
        }
    }
    
}
