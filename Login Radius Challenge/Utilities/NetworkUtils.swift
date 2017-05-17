//
//  NetworkUtils.swift
//  Login Radius Challenge
//
//  Created by Thompson Sanjoto on 2017-04-08.
//  Copyright © 2017 Thompson Sanjoto. All rights reserved.
//

import Foundation
import SwiftHTTP
import SwiftyJSON

class NetworkUtils
{

    class func restCall(_ url:String,
                        method:HTTPVerb,
                        queryParam: [String:String]? = nil,
                        parameters: HTTPParameterProtocol? = nil,
                        headers:[String:String]?=nil,
                        completion:((_ response:Response)->Void)?)
    {
        var newUrl = url
        
        //modify the url to add any parameters
        if let qParam = queryParam
        {
            var i = 0
            for (k,v) in qParam
            {
                let prefix = (i == 0) ? "?" : "&"
                newUrl += "\(prefix)\(k)=\(v)"
                i += 1
            }
        }
        
        var requestSerializer:HTTPSerializeProtocol
        if parameters == nil
        {
            requestSerializer = HTTPParameterSerializer()
        }else
        {
            requestSerializer = JSONParameterSerializer()
        }
        
        do
        {
            let opt = try HTTP.New(newUrl, method: method, parameters: parameters, headers: headers, requestSerializer: requestSerializer)
            
            // override the SSL
            var attempted = false
            opt.auth =
            {
                    challenge in
                    if !attempted
                    {
                        attempted = true
                        return URLCredential(trust: challenge.protectionSpace.serverTrust!)
                    }
                    return nil
            }
            if let callback = completion
            {
                opt.start(callback)
            }else
            {
                opt.start()
            }
        }
        catch let error
        {
            print("Got an error trying to send: \(error)")
        }
    }
    
    class func parseLoginRadiusError(response:Response) -> String
    {
        var errorMsg = "Unknown Error"
        
        //error message from payload data
        if let dataJSON = JSON(data:response.data).dictionary,
           let errMsg = dataJSON["message"]?.string
        {
            errorMsg = errMsg
        } //error message from header
        else if let _ = response.error
        {
            errorMsg = response.description
        }
        
        return errorMsg
    }
}
