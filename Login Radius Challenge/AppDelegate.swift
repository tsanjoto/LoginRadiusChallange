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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //Skip using config.plist, don't really wanna handle reading off plist
    static var apiKey: String = "94dd8825-669d-44f3-ae1a-5f0828016ae6"
    static var apiSecret: String = "07cc3051-ff45-465e-a69b-9b97e2e3dc80"
    static var siteName: String = "lr-candidate-demo3"
    
    var userToken: String? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let sdk:LoginRadiusSDK = LoginRadiusSDK.instance();
        sdk.applicationLaunched(options: launchOptions);
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool{
        
        let urlStr = url.absoluteString
        let checkForToken  = urlStr.components(separatedBy: "lr-token=")

        if checkForToken.count == 2
        {
            getUserProfileInfo(token:checkForToken[1])
        }

        return true
    }
    
    func getUserProfileInfo(token:String)
    {
        let url = LoginRadiusUrlMethods.base + LoginRadiusUrlMethods.getUserInfoViaToken
        let queryParam  = ["access_token": token]
        
        NetworkUtils.restCall(url, method: .GET, queryParam: queryParam, parameters: nil, headers: nil, completion: {(response)->Void in
            
            //this is the same as saving profile
            if let _ = response.error
            {
                if NetworkUtils.parseLoginRadiusError(response: response) == "Access token is invalid"
                {
                    let renewTokenUrl = LoginRadiusUrlMethods.base + LoginRadiusUrlMethods.renewAccessToken
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
                    let mainVC = navVC.viewControllers[0] as? MainViewController,
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
                DispatchQueue.main.async {
                    //should use notification
                    if let navVC = self.window!.rootViewController as? UINavigationController,
                        let mainVC = navVC.viewControllers[0] as? MainViewController
                    {
                        mainVC.dismiss(animated: true, completion: {
                            mainVC.showProfileController()
                        })
                    }
                }
            }
        })

    }


   
}

