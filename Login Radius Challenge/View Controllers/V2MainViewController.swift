//
//  V2MainViewController.swift
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

class V2MainViewController: FormViewController, SFSafariViewControllerDelegate, ProfilePresenter, GIDSignInUIDelegate {
    
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
        
        GIDSignIn.sharedInstance().uiDelegate = self

        // Do any additional setup after loading the view, typically from a nib.
        self.tabBarController?.navigationItem.title = "Login Radius V2"
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
                $0.value = "thompson.sanjoto+7@loginradius.com"
                $0.add(rule: RuleRequired(msg: "Email Required"))
                $0.add(rule: RuleEmail(msg: "Incorrect Email format"))
            }
            <<< PasswordRow("Password Login")
            {
                $0.title = "Password"
                $0.hidden = loginCondition
                $0.value = "password"
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
                $0.value = "thompson.sanjoto+3@loginradius.com"
                $0.add(rule: RuleRequired(msg: "Email Required"))
                $0.add(rule: RuleEmail(msg: "Incorrect Email format"))
            }
            <<< PasswordRow("Password Register")
            {
                $0.title = "Password"
                $0.hidden = registerCondition
                $0.value = "password"
                $0.add(rule: RuleRequired(msg: "Password Required"))
                $0.add(rule: RuleMinLength(minLength: 6, msg: "Length of password must be at least 6"))
            }
            <<< PasswordRow("Confirm Password") {
                $0.title =  $0.tag
                $0.hidden = registerCondition
                $0.value = "password"
                $0.add(rule: RuleRequired(msg: "Confirming your password is required"))
                $0.add(rule: RuleEqualsToRow(form: self.form, tag: "Password Register", msg: "Mismatch on confirming your password"))
            }
            <<< ButtonRow("Register send")
            {
                $0.title = "Register"
                $0.hidden = registerCondition
                }.onCellSelection{ row in
                    self.requestSOTT()
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
                $0.value = "thompson.sanjoto+7@loginradius.com"
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
            
            +++ Section("Social Logins Normal")
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
            +++ Section("Social Logins Native")
            <<< ButtonRow("Google Native")
            {
                $0.title = "Google"
                }.onCellSelection{ row in
                    self.showNativeGoogleLogin()
            }
            <<< ButtonRow("Facebook Native")
            {
                $0.title = "Facebook"
                }.onCellSelection{ row in
                    self.showNativeFacebookLogin()
            }
            <<< ButtonRow("Twitter Native")
            {
                $0.title = "Twitter"
                }.onCellSelection{ row in
                    self.showNativeTwitterLogin()

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
                          "email": emailEncoded,
                          "password": form.rowBy(tag: "Password Login")!.baseValue! as! String,
                          ]
        
        let url = LoginRadiusUrlMethodsV2.base + LoginRadiusUrlMethodsV2.login
        
        
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
    func register(sott:String)
    {
        var errors = form.rowBy(tag: "Email Register")!.validate()
        errors += form.rowBy(tag: "Password Register")!.validate()
        errors += form.rowBy(tag: "Confirm Password")!.validate()
        
        if errors.count > 0
        {
            AlertUtils.showAlert(self, title: "ERROR", message: errors[0].msg, completion: nil)
            return
        }
        
        
        let email:AnyObject = ["Type":"Primary",
                                "Value":form.rowBy(tag: "Email Register")!.baseValue!
                            ] as AnyObject

        let parameter = [  "Email": [
                                        email
                                    ],
                           "Password": form.rowBy(tag: "Password Register")!.baseValue!,
        ]
        
        let queryParam = ["apikey":AppDelegate.apiKey,
                          "sott": sott,
                          "verificationUrl":localNodeJS.base+localNodeJS.register]
        
        let url = LoginRadiusUrlMethodsV2.base + LoginRadiusUrlMethodsV2.register
        
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
    
    //Request SOTT from localserver after client side validation
    func requestSOTT()
    {
        
        let url = localNodeJS.base + localNodeJS.sott
        
        NetworkUtils.restCall(url , method: .GET, queryParam:nil, parameters: nil, completion: {
            (response)->Void in
            
            if let sott = response.text,
                !sott.isEmpty
            {
                self.register(sott:sott)
            }else
            {
                print(response.error?.description ?? "Unknown error")
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
                //self.register(response.data)
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
        
        let queryParam = ["apikey":AppDelegate.apiKey,
        "resetPasswordUrl":localNodeJS.base+localNodeJS.reset]
        
        let params = ["email":email]
        
        let url = LoginRadiusUrlMethodsV2.base + LoginRadiusUrlMethodsV2.forgotPassword
        print(url)
        NetworkUtils.restCall(url , method: .POST, queryParam:queryParam, parameters: params, completion: {
            (response)->Void in
            
            if let err = response.error
            {
                print(err.description)
                AlertUtils.showAlert(self, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
            }else
            {
                print(response.description)
                var message = "Error requesting the forgot password"
                let json = JSON(data:response.data)
                if let isPosted = json["IsPosted"].bool
                {
                    if isPosted
                    {
                        message = "Request for your password is succesful, press the link in your email"
                    }
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
                AlertUtils.showAlert(self, title: "ERROR", message: "Failed to logged in", completion: nil)
            }
        });
    }
    
    func showNativeGoogleLogin()
    {
        //LoginRadiusSocialLoginManager.sharedInstance().nativeGoogleLogin(withAccessToken: <#T##String!#>, completionHandler: <#T##LRServiceCompletionHandler!##LRServiceCompletionHandler!##(Bool, Error?) -> Void#>)
        GIDSignIn.sharedInstance().signIn()
    }
    
    func showNativeFacebookLogin()
    {
        LoginRadiusSocialLoginManager.sharedInstance().nativeFacebookLogin(withPermissions: ["facebookPermissions": ["public_profile"]], in: self, completionHandler:  {(_ success: Bool, _ error: Error?) -> Void in
            
            if success
            {
                self.showProfileController()
            }else
            {
                AlertUtils.showAlert(self, title: "ERROR", message: "Failed to use Native Facebook Login", completion: nil)
            }
        })

    }
    
    func showNativeTwitterLogin()
    {
        
        LoginRadiusSocialLoginManager.sharedInstance().nativeTwitter(withConsumerKey: "dbkgjT2wpgX32mnAHGtxkbs38", consumerSecret: "6yA3BmYuAYA6MIQwLGyo0sS1T8hUwafHq98wyrsBUhd7Asj722", in: self, completionHandler: {(_ success: Bool, _ error: Error?) -> Void in
            
            if success
            {
                self.showProfileController()
            }else
            {
                AlertUtils.showAlert(self, title: "ERROR", message: "Failed to use Native Twitter Login", completion: nil)
            }
        })
    }
    
    func showProfileController () {
        self.performSegue(withIdentifier: "profile", sender: self);
    }
    
    //to eliminate "< Back" button showing up when user already logged in
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "profile"
        {
            if let detailVC = segue.destination as? DetailViewController
            {
                detailVC.urlMethods = 2
            }
            segue.destination.navigationItem.hidesBackButton = true
        }
    }
    
}

