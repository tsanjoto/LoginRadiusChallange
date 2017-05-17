//
//  Gender.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-09.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation

enum Gender:String
{
    case male            = "M"
    case female          = "F"
    case unknown         = "U"
    var symbol: String
    {
        switch self
        {
        case .male: return "♂"
        case .female: return "♀"
        case .unknown: return "?"
        }
    }
    
    static var allPossibleGendersSymbols:[String] = [Gender.male.symbol,Gender.female.symbol,Gender.unknown.symbol]
    
    init?(string: String?) {
        
        guard let string = string else
        {
            self = .unknown
            return
        }
        
        switch string.lowercased() {
        case "♂":
            fallthrough
        case "m":
            self = .male
        case "♀":
            fallthrough
        case "f":
            self = .female
        case "u":
            fallthrough
        default:
            self = .unknown
        }
    }
}
