//
//  AppDelegate.m
//  PokeMonFinder
//
//  Created by MG on 20/08/2016.
//  Copyright © 2016 MG. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate () <UISplitViewControllerDelegate, CLLocationManagerDelegate, GADInterstitialDelegate, FHSTwitterEngineAccessTokenDelegate> {
    
    CLLocationManager* _myLocationManager;
    GADInterstitial* _interstitial;
    NSTimer* _timer;
    BOOL _isDimissedInterstitial;
}

@property (nonatomic, strong) ECSlidingViewController *slidingViewController;
@end


@implementation AppDelegate

@synthesize sideVC;
@synthesize myLocation;
@synthesize transitions;
@synthesize session;

+(AppDelegate *)instance {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.    
    [MGUIAppearance enhanceNavBarAppearance:NAV_BAR_BG];
    [MGUIAppearance enhanceBarButtonAppearance:WHITE_TINT_COLOR];
    [MGUIAppearance enhanceToolbarAppearance:NAV_BAR_BG];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_8_4
    if (DOES_SUPPORT_IOS7) {
        [application setStatusBarStyle:UIStatusBarStyleLightContent];
    }
#endif
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController* navController = [storyboard instantiateViewControllerWithIdentifier:@"storyboardNavigation"];
    navController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    sideVC = [storyboard instantiateViewControllerWithIdentifier:@"storyboardSideView"];
    
    self.slidingViewController = [ECSlidingViewController slidingWithTopViewController:navController];
    self.slidingViewController.underLeftViewController  = sideVC;
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGesturePanning | ECSlidingViewControllerAnchoredGestureTapping;
    self.slidingViewController.anchorRightPeekAmount  = ANCHOR_LEFT_PEEK; //44.0
    self.slidingViewController.anchorLeftRevealAmount = ANCHOR_RIGHT_PEEK; //276.0
    self.window.rootViewController = self.slidingViewController;
    [self.window makeKeyAndVisible];
    [self setTransitionIndex:0];
    
    [[FHSTwitterEngine sharedEngine] permanentlySetConsumerKey:TWITTER_CONSUMER_KEY
                                                     andSecret:TWITTER_CONSUMER_SECRET];
    
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    
    _isDimissedInterstitial = YES;
    if(SHOW_INTERSTITIAL) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:INTERSTITIAL_DELAY_IN_SECONDS
                                                  target:self
                                                selector:@selector(showInterstitial) userInfo:nil repeats:YES];
    }
    
    return YES;
}

#pragma mark - TWITTER

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"TWITTER_ACCESS_TOKEN"];
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"TWITTER_ACCESS_TOKEN"];
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
    
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:self.session];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
    [self.session close];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    // You can add your app-specific url handling code here if needed
    
    if(!wasHandled) {
        wasHandled = [[GIDSignIn sharedInstance] handleURL:url
                                         sourceApplication:sourceApplication
                                                annotation:annotation];
    }
    return wasHandled;
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
//    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
//        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//        return YES;
//    } else {
//        return NO;
//    }
    
    return NO;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.projects.PokeMonFinder" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PokeMonFinder" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PokeMonFinder.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - ECSLIDING DELEGATE

-(int)getTransitionIndex {
    return [[[NSUserDefaults standardUserDefaults]objectForKey:@"TRANSITION_INDEX"] intValue];
}

-(void)setTransitionIndex:(int)index {
    
    NSDictionary *transitionData = self.transitions.all[index];
    id<ECSlidingViewControllerDelegate> transition = transitionData[@"transition"];
    
    if (transition == (id)[NSNull null]) {
        self.slidingViewController.delegate = nil;
    } else {
        self.slidingViewController.delegate = transition;
    }
    
    [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%d", index] forKey:@"TRANSITION_INDEX"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (METransitions *)transitions {
    if (transitions) return transitions;
    
    transitions = [[METransitions alloc] init];
    return transitions;
}

#pragma mark - FIND USER LOCATION

-(void)findMyCurrentLocation {
    if(_myLocationManager == nil) {
        _myLocationManager = [[CLLocationManager alloc] init];
        _myLocationManager.delegate = self;
    }
    if(IS_OS_8_OR_LATER) {
        [_myLocationManager requestAlwaysAuthorization];
    }
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
        authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [_myLocationManager startUpdatingLocation];
    }
    if( [CLLocationManager locationServicesEnabled] ) {
        NSLog(@"Location Services Enabled....");
    }
    else {
        if([self.locationDelegate respondsToSelector:@selector(appDelegate:sensorError:)])
            [self.locationDelegate appDelegate:self sensorError:_myLocationManager];
    }
}

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation {
    myLocation = newLocation;
    [self.locationDelegate appDelegate:self
                       locationManager:manager
                   didUpdateToLocation:newLocation
                          fromLocation:oldLocation];
}

-(void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error {
    [self.locationDelegate appDelegate:self
                       locationManager:manager
                      didFailWithError:error];
}

-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc atScrollViewOffsetAdjustment:(UIScrollView*)scrollView{
    [MGUtilities createAdAtY:vc.view.frame.size.height - AD_BANNER_HEIGHT
              viewController:vc
                     bgColor:AD_BG_COLOR];
    
    if(scrollView != nil) {
        UIEdgeInsets inset = scrollView.contentInset;
        inset.bottom = ADV_VIEW_OFFSET;
        scrollView.contentInset = inset;
        inset = scrollView.scrollIndicatorInsets;
        inset.bottom = ADV_VIEW_OFFSET;
        scrollView.scrollIndicatorInsets = inset;
    }
}

-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc atTableViewOffsetAdjustment:(UITableView*)tableView {
    
    GADBannerView* view = [MGUtilities createAdAtY:vc.view.frame.size.height - AD_BANNER_HEIGHT
                                    viewController:vc
                                           bgColor:AD_BG_COLOR];
    
    view.backgroundColor = AD_BG_COLOR;
    if(tableView != nil) {
        UIEdgeInsets inset = tableView.contentInset;
        inset.bottom = ADV_VIEW_OFFSET;
        tableView.contentInset = inset;
        
        inset = tableView.scrollIndicatorInsets;
        inset.bottom = ADV_VIEW_OFFSET;
        tableView.scrollIndicatorInsets = inset;
    }
}

-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc {
    
    GADBannerView* view = [MGUtilities createAdAtY:vc.view.frame.size.height - AD_BANNER_HEIGHT
                                    viewController:vc
                                           bgColor:AD_BG_COLOR];
    
    view.backgroundColor = AD_BG_COLOR;
}

-(void)resetView {
    [sideVC resetView];
}

- (void)createAndLoadInterstitial {
    _interstitial = [[GADInterstitial alloc] initWithAdUnitID:INTERSTITIAL_UNIT_ID];
    _interstitial.delegate = self;
    GADRequest *request = [GADRequest request];
    // Request test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made.
    
    if(!REMOVE_TEST_ADS)
        request.testDevices = TEST_ADS_ID;
    
    [_interstitial loadRequest:request];
}

-(void)showInterstitial {
    
    if(!_isDimissedInterstitial)
        return;
    
    [self createAndLoadInterstitial];
    
}

-(void)interstitialDidReceiveAd:(GADInterstitial *)ad {
    _isDimissedInterstitial = NO;
    [_interstitial presentFromRootViewController:self.window.rootViewController];
}

-(void)interstitialDidDismissScreen:(GADInterstitial *)ad {
    _isDimissedInterstitial = YES;
}

@end
