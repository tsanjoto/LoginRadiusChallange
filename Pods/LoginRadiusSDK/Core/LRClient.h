//
//  LRClient.h
//  Pods
//
//  Created by Raviteja Ghanta on 20/02/17.
//
//

#import <Foundation/Foundation.h>
#import "LoginRadius.h"

@interface LRClient : NSObject

/**
 *  shared singleton
 *
 *  @return singleton instance of REST client
 */
+ (instancetype) sharedInstance;

- (void)getUserProfileWithAccessToken:(NSString *)token completionHandler:(LRAPIResponseHandler) completion;

- (void)updateUserProfileWithAccessToken:(NSString *) token
                                  appkey:(NSString *) appkey
                               appsecret:(NSString *) appsecret
                              parameters:(NSDictionary *) parameters
                       completionHandler:(LRAPIResponseHandler) completion;


@end
