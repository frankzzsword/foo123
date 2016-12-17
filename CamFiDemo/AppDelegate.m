//
//  AppDelegate.m
//  CamFiDemo
//
//  Created by Justin on 16/5/29.
//  Copyright © 2016年 CamFi. All rights reserved.
//

#import "AppDelegate.h"
#import "CamFiServerInfo.h"
#import "SDWebImageManager.h"

@interface AppDelegate ()

@end


@implementation AppDelegate

- (void)enableWifiBridgingWithSSID:(NSString *)ssid password:(NSString *)password encryption:(NSString *)encryption
{
    NSURL *serverURL = [NSURL URLWithString:CamFiServerInfo.sharedInstance.camFiNetworkModeURLStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:serverURL];
    request.HTTPMethod = @"POST";

    NSDictionary *body = @
    {
        @"mode": @"sta",
        @"router_ssid": ssid,
        @"password": password,
        @"encryption": encryption
    };
    
    NSError *jsonError;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:&jsonError];
    
    if (jsonError != nil)
    {
        NSLog(@"JSON error: %@", jsonError);
    }

    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        NSLog(@"network mode");
        NSLog(@"response: %@", response);
        if (error != nil)
        {
            NSLog(@"error: %@", response);
        }
    }];

    [task resume];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        [self enableWifiBridgingWithSSID:@"Default5" password:@"12121212121212121212121212" encryption:@"psk2"];
    });

    [[SDWebImageManager sharedManager] imageCache].shouldCacheImagesInMemory = NO;
    
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
