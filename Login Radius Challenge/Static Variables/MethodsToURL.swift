//
//  LoginRadiusMethods.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-09.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation

struct LoginRadiusUrlMethodsV1
{
    static var base = "http://api.loginradius.com"
    static var register = "/raas/v1/user/register"
    static var login = "/raas/client/auth/login"
    static var updateUserProfile = "/raas/v1/user/update"
    static var forgotPassword = "/raas/v1/account/password/forgot"
    //static var resetPassword = ""
    //got an for reset password natively. When I did a rest call directly, server returns an error saying its an unauthorized endpoint.
    //well an app natively doesn't really have a url...
    static var getUserInfoViaToken = "/api/v2/userprofile" // no v1 version.
    static var renewAccessToken = "/api/v2/access_token" // no v1 version.
}

struct LoginRadiusUrlMethodsV2
{
    static var base = "http://api.loginradius.com"
    static var register = "/identity/v2/auth/register"
    static var login = "/identity/v2/auth/login"
    static var updateUserProfile = "/identity/v2/auth/account"
    static var forgotPassword = "/identity/v2/auth/password"
    static var getUserInfoViaToken = "/api/v2/userprofile"
    static var renewAccessToken = "/api/v2/access_token"
}

//This github.io are static pages that uses the demo LoginRadiusSaaS.js
struct TsanjotoGithubio
{
    static var base = "https://tsanjoto.github.io"
    static var emailVer = "/email-verification.html"
    static var resetPassword = "/reset-password.html"
    static var socialLogin = "/social.html"
}

//Small server to generate sott locally
struct localNodeJS
{
    static var base = "http://localhost:3000"
    static var sott = "/sott"
    static var register = "/register"
    static var reset = "/reset"
}
