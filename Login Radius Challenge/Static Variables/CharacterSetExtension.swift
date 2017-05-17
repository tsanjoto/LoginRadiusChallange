//
//  CharacterSetExtension.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-09.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation

extension CharacterSet
{
    //found a bug where I successfully registered an email with "+" character in it, but server didn't found any
    //this is the solution
    public static var allowedEmailCharacter: CharacterSet = CharacterSet(charactersIn:"!#$%&'*+-/=?^_`{|}~").inverted
}
