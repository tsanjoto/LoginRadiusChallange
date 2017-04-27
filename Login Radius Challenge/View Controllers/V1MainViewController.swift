//
//  V1MainViewController.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-08.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import UIKit
import Eureka
import SwiftyJSON
import SafariServices
import LoginRadiusSDK


protocol ProfilePresenter
{
    func showProfileController() -> Void
}

class V1MainViewController: FormViewController, SFSafariViewControllerDelegate, ProfilePresenter {
    
    var forgotPasswordToken:String? = nil
    {
        //trigger UI if forgot password token came back
        didSet
        {
            DispatchQueue.main.async
            {
                let resetPasswordSection = self.form.sectionBy(tag: "Reset Password")!
                resetPasswordSection.hidden = Condition(booleanLiteral:  (self.forgotPasswordToken == nil))
                resetPasswordSection.evaluateHidden()
            }

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.tabBarController?.navigationItem.title = "Login Radius V1"
        self.form = Form()
        
        //These is the just rules to toggle visibility of the UI elements
        let loginCondition = Condition.function(["Login"], { form in
            return !((form.rowBy(tag: "Login") as? SwitchRow)?.value ?? false)
        })

        let registerCondition = Condition.function(["Register"], { form in
            return !((form.rowBy(tag: "Register") as? SwitchRow)?.value ?? false)
        })
        
        let forgotCondition = Condition.function(["Forgot Password"], { form in
            return !((form.rowBy(tag: "Forgot Password") as? SwitchRow)?.value ?? false)
        })
        //end of conditions
        
        //Create UI forms
        form  +++ Section("Normal Login Features")
            <<< SwitchRow("Login")
            {
                $0.title = $0.tag
            }
            <<< EmailRow("Email Login")
            {
                $0.title = "Email"
                $0.hidden = loginCondition
                $0.add(rule: RuleRequired(msg: "Email Required"))
                $0.add(rule: RuleEmail(msg: "Incorrect Email format"))
            }
            <<< PasswordRow("Password Login")
            {
                $0.title = "Password"
                $0.hidden = loginCondition
                $0.add(rule: RuleRequired(msg: "Password Required"))
                $0.add(rule: RuleMinLength(minLength: 6, msg: "Length of password must be at least 6"))
            }
            <<< ButtonRow("Login send")
            {
                $0.title = "Login"
                $0.hidden = loginCondition
                }.onCellSelection{ row in
                    self.normalLogin()
            }
            
            +++ Section("Register Section")
            {
                $0.header = nil
            }
            <<< SwitchRow("Register")
            {
                $0.title = $0.tag
            }
            <<< EmailRow("Email Register")
            {
                $0.title = "Email"
                $0.hidden = registerCondition
                $0.add(rule: RuleRequired(msg: "Email Required"))
                $0.add(rule: RuleEmail(msg: "Incorrect Email format"))
            }
            <<< PasswordRow("Password Register")
            {
                $0.title = "Password"
                $0.hidden = registerCondition
                $0.add(rule: RuleRequired(msg: "Password Required"))
                $0.add(rule: RuleMinLength(minLength: 6, msg: "Length of password must be at least 6"))
            }
            <<< PasswordRow("Confirm Password") {
                $0.title =  $0.tag
                $0.hidden = registerCondition
                $0.add(rule: RuleRequired(msg: "Confirming your password is required"))
                $0.add(rule: RuleEqualsToRow(form: self.form, tag: "Password Register", msg: "Mismatch on confirming your password"))
            }
            <<< ButtonRow("Register send")
            {
                $0.title = "Register"
                $0.hidden = registerCondition
                }.onCellSelection{ row in
                    self.register()
            }
            +++ Section("Forgot Password Section")
            {
                $0.header = nil
            }
            <<< SwitchRow("Forgot Password")
            {
                $0.title = $0.tag
                
            }
            <<< EmailRow("Email Forgot")
            {
                $0.title = "Email"
                $0.hidden = forgotCondition
                $0.add(rule: RuleRequired(msg: "Email Required"))
                $0.add(rule: RuleEmail(msg: "Incorrect Email format"))
            }
            <<< ButtonRow("Forgot send")
            {
                $0.title = "Request Password"
                $0.hidden = forgotCondition
                }.onCellSelection{ row in
                    self.forgotPassword()
            }
            
            +++ Section("Reset Password")
            {
                $0.tag = "Reset Password"
                $0.hidden = Condition(booleanLiteral:  true)
            }
            <<< ButtonRow("Reset Password")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.resetPassword()
            }
            
            +++ Section("Social Logins")
            <<< ButtonRow("Google")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.showSocialLogins(provider:"google")
            }
            <<< ButtonRow("Facebook")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.showSocialLogins(provider:"facebook")
            }
            <<< ButtonRow("Twitter")
            {
                $0.title = $0.tag
                }.onCellSelection{ row in
                    self.showSocialLogins(provider:"twitter")
            }
        
    }

    //Functionality Area
    
    ///Validate and Send UI information to perform Normal user login in LoginRadius
    func normalLogin()
    {
        var errors = form.rowBy(tag: "Email Login")!.validate()
        errors += form.rowBy(tag: "Password Login")!.validate()
        
        if errors.count > 0
        {
            AlertUtils.showAlert(self, title: "ERROR", message: errors[0].msg, completion: nil)
            return
        }
        
        let email = form.rowBy(tag: "Email Login")!.baseValue! as! String
        let emailEncoded = email.addingPercentEncoding(withAllowedCharacters: .allowedEmailCharacter)!

        let queryParam = ["apikey":AppDelegate.apiKey,
                          "emailid": emailEncoded,
                          "password": form.rowBy(tag: "Password Login")!.baseValue! as! String,
        ]
        
        let url = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.login
        
        
        NetworkUtils.restCall(url, method: .GET, queryParam:queryParam, parameters: nil, headers: nil, completion: {
            (response)->Void in
            
            if let _ = response.error
            {
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
            }else
            {
                if let userData = JSON(data:response.data).dictionary
                {
                    let defaults = UserDefaults.standard

                    if let token = userData["access_token"]?.string,
                        let expire = userData["expires_in"]?.string,
                        let profile = userData["Profile"]?.rawString()
                    {
                        defaults.setValue(token, forKeyPath: "lrAccessToken")
                        defaults.setValue(expire, forKeyPath: "lrAccessTokenExpiry")
                        defaults.setValue(profile, forKeyPath: "lrUserProfile")
                        DispatchQueue.main.async {
                            self.showProfileController()
                        }
                    }else
                    {
                        //apparently wrong password still gives code 200, not 403
                        AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
                    }

                }
            }
            
        })
    }
    
    ///Validate and Send UI information to perform Normal user registration in LoginRadius
    func register()
    {
        var errors = form.rowBy(tag: "Email Register")!.validate()
        errors += form.rowBy(tag: "Password Register")!.validate()
        errors += form.rowBy(tag: "Confirm Password")!.validate()

        if errors.count > 0
        {
            AlertUtils.showAlert(self, title: "ERROR", message: errors[0].msg, completion: nil)
            return
        }
        
        let parameter = [  "emailid": form.rowBy(tag: "Email Register")!.baseValue!,
                           "password": form.rowBy(tag: "Password Register")!.baseValue!,
                           "emailverificationurl": TsanjotoGithubio.base+TsanjotoGithubio.emailVer
                        ]
        
        let queryParam = ["appkey":AppDelegate.apiKey, "appsecret":AppDelegate.apiSecret]
        
        let url = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.register
        
        NetworkUtils.restCall(url , method: .POST, queryParam:queryParam, parameters: parameter, completion: {
            (response)->Void in
            
            if let err = response.error
            {
                print(err.description)
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
            }else
            {
                AlertUtils.showAlert(self, title: "Success", message: "Check your email for verification link", completion: nil)
            }
            
        })
        
    }

    ///Validate and Send UI information to perform forgot password in LoginRadius
    func forgotPassword()
    {
        var errors = form.rowBy(tag: "Email Forgot")!.validate()
        
        if errors.count > 0
        {
            AlertUtils.showAlert(self, title: "ERROR", message: errors[0].msg, completion: nil)
            return
        }
        let email = form.rowBy(tag: "Email Forgot")!.baseValue! as! String
        let emailEncoded = email.addingPercentEncoding(withAllowedCharacters: .allowedEmailCharacter)!

        let queryParam = ["appkey":AppDelegate.apiKey,
                          "appsecret":AppDelegate.apiSecret,
                          "email": emailEncoded
                        ]
        
        let url = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.forgotPassword
        
        NetworkUtils.restCall(url , method: .GET, queryParam:queryParam, parameters: nil, completion: {
            (response)->Void in
            
            if let err = response.error
            {
                print(err.description)
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
            }else
            {
                print(response.description)
                var message = ""
                let json = JSON(data:response.data)
                if let guid = json["Guid"].string
                {
                    self.forgotPasswordToken = guid
                    message = "Request for your password is succesful, press the reset password"
                }else if let providersArr = json["Providers"].array
                {
                    let providers = providersArr.map({$0.stringValue})
                    message = "Seems like you register through social login \(providers), use it!"
                }else
                {
                    //I have no idea how to handle if Guid is null and providers is null
                    message = "Unknown Error"
                }
                
                AlertUtils.showAlert(self, title: "Success", message: message, completion: nil)
            }
            
        })
    }
    
    /// reset password, assume token is given
    func resetPassword()
    {
        //got an error on sending the token directly from the app, saying need an authorized endpoint.
        //well an app natively doesn't really have a url...
        //have to resort opening a web and use the demo server through js
        let url = URL(string:TsanjotoGithubio.base+TsanjotoGithubio.resetPassword+"?vtoken=\(forgotPasswordToken!)")!
        let safariVC = SFSafariViewController(url:url)
        self.navigationController?.pushViewController(safariVC, animated: true)
        
        
    }
    
    func showSocialLogins(provider:String)
    {
        LoginRadiusSocialLoginManager.sharedInstance().login(withProvider: provider, in: self, completionHandler: { (success, error) in
            if (success) {
                //this needs to be handled from app delegate call, see AppDelegate.swift
                print("successfully logged in with \(provider)");
            } else {
                
            }
        });
    }

    
    func showProfileController () {
        self.performSegue(withIdentifier: "profile", sender: self);
    }
    
    //to eliminate "< Back" button showing up when user already logged in
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile"
        {
            segue.destination.navigationItem.hidesBackButton = true
        }
    }
}

