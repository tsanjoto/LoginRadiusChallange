//
//  AppDelegate.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-08.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import UIKit
import SwiftyJSON
import SafariServices
import LoginRadiusSDK
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {


    var window: UIWindow?

    //Skip using config.plist, don't really wanna handle reading off plist
    static var apiKey: String = "aad1d378-8613-429b-b728-bb2550e453f3"
    static var apiSecret: String = "b49136b3-dbe5-4e7b-83d0-519bb251c23a"
    static var siteName: String = "lr-thompson"
    var userToken: String? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let sdk:LoginRadiusSDK = LoginRadiusSDK.instance();
        sdk.applicationLaunched(options: launchOptions);
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        
        //this should definitely handled inside the LoginRadiusSDK pod
        
        let LRPlistPath:String = Bundle.main.path(forResource: "LoginRadius", ofType: "plist")!
        let values = NSDictionary(contentsOfFile: LRPlistPath)!
        let googleKey:String? = values["GoogleNativeKey"] as? String //for the loginradiussdk pod set static string variable
        let facebookKey:String? = values["FacebookNativeKey"] as? String //same for this one
        
        var shouldOpen:Bool = false
        // if only switch statement can unwrap optionals...
        if url.scheme == AppDelegate.siteName
        {
            //this is coming from normal LR logins
            let checkForToken  = url.absoluteString.components(separatedBy: "lr-token=")
            
            if checkForToken.count == 2
            {
                getUserProfileInfo(token:checkForToken[1])
                shouldOpen = true
            }
        } else if let gKey = googleKey,
            url.scheme ==  gKey
        {
            //native google login
            shouldOpen = GIDSignIn.sharedInstance().handle(url,
                                            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                            annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        }else if let fKey = facebookKey,
            url.scheme == fKey
        {
            //native facebook login
            shouldOpen = LoginRadiusSDK.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            
        }


        return shouldOpen
    }
    
    func getUserProfileInfo(token:String)
    {
        let url = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.getUserInfoViaToken
        let queryParam  = ["access_token": token]
        
        NetworkUtils.restCall(url, method: .GET, queryParam: queryParam, parameters: nil, headers: nil, completion: {(response)->Void in
            
            //this is the same as saving profile
            if let _ = response.error
            {
                if NetworkUtils.parseLoginRadiusError(response: response) == "Access token is invalid"
                {
                    let renewTokenUrl = LoginRadiusUrlMethodsV1.base + LoginRadiusUrlMethodsV1.renewAccessToken
                    let queryParam  = ["secret": AppDelegate.apiSecret,"token": token]
                    NetworkUtils.restCall(renewTokenUrl, method: .GET, queryParam: queryParam, parameters: nil, headers: nil, completion: {(response)->Void in
                        if let _ = response.error
                        {
                            print("error occured")
                        }else
                        {
                            let json = JSON(data: response.data)
                            
                            self.getUserProfileInfo(token: json["access_token"].stringValue)
                        }
                        
                        
                    })
                }else if let navVC = self.window!.rootViewController as? UINavigationController,
                    let mainVC = navVC.viewControllers[0] as? V1MainViewController,
                    let safariVC = mainVC.presentedViewController as? SFSafariViewController
                {
                    AlertUtils.showAlert(safariVC, title: "ERROR", message: NetworkUtils.parseLoginRadiusError(response: response), completion: nil)
                    
                }
                
            }else
            {
                let userData = JSON(data:response.data)
                let defaults = UserDefaults.standard
                defaults.setValue(token, forKeyPath: "lrAccessToken")
                defaults.setValue(userData.rawString(), forKeyPath: "lrUserProfile")
                //should use event emitter
                self.showProfileScreen()
                
            }
        })

    }
    
    func showProfileScreen()
    {
        DispatchQueue.main.async {
            //should use notification
            if let tabVC = self.window!.rootViewController as? UITabBarController,
                let navVC = tabVC.selectedViewController as? UINavigationController,
                let pp =  navVC.viewControllers[0] as? ProfilePresenter
            {
                if navVC.viewControllers[0].presentedViewController != nil
                {
                    //dismiss safariwebview
                    navVC.viewControllers[0].dismiss(animated: true, completion: {
                        pp.showProfileController()
                    })
                }else
                {
                    //if native google/facebook have session handler and skipped showing safari
                    pp.showProfileController()
                }
            }
        }
    }
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let idToken: String = user.authentication.accessToken
        LoginRadiusSocialLoginManager.sharedInstance().nativeGoogleLogin(withAccessToken: idToken, completionHandler: {(_ success: Bool, _ error: Error?) -> Void in
            if success {
                print("successfully logged in with google")
                self.showProfileScreen()
            }
            else {
                print("Error: \(String(describing: error?.localizedDescription))")
            }
        })

    }
}

