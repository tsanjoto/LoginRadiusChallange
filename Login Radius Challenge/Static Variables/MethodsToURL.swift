//
//  LoginRadiusMethods.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-09.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation

struct LoginRadiusUrlMethods
{
    static var base = "http://api.loginradius.com"
    static var register = "/raas/v1/user/register"
    static var login = "/raas/client/auth/login"
    static var updateUserProfile = "/raas/v1/user/update"
    static var forgotPassword = "/raas/v1/account/password/forgot"
    static var resetPassword = "/identity/v2/auth/password"
    static var getUserInfoViaToken = "/api/v2/userprofile"
    static var renewAccessToken = "/api/v2/access_token"
}


struct TsanjotoGithubio
{
    static var base = "https://tsanjoto.github.io"
    static var emailVer = "/email-verification.html"
    static var resetPassword = "/reset-password.html"
    static var socialLogin = "/social.html"


}
