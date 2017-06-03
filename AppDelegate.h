//
//  AppDelegate.h
//  PokeMonFinder
//
//  Created by MG on 20/08/2016.
//  Copyright © 2016 MG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SideVC.h"

@class AppDelegate;

@protocol LocationDelegate <NSObject>
-(void) appDelegate:(AppDelegate*)appDelegate locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
       fromLocation:(CLLocation *)oldLocation;

-(void) appDelegate:(AppDelegate*)appDelegate locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error;

@optional
-(void) appDelegate:(AppDelegate*)appDelegate sensorError: (CLLocationManager *)manager;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, retain) id <LocationDelegate> locationDelegate;
@property (nonatomic, strong) CLLocation* myLocation;
-(void)findMyCurrentLocation;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (nonatomic, strong) SideVC* sideVC;
+(AppDelegate*) instance;
@property (nonatomic, strong) METransitions *transitions;

- (METransitions *)transitions;
-(void)setTransitionIndex:(int)index;
-(int)getTransitionIndex;

-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc atTableViewOffsetAdjustment:(UITableView*)tableView;
-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc atScrollViewOffsetAdjustment:(UIScrollView*)scrollView;
-(void)showAdsAtOffsetY:(int)y atViewController:(UIViewController*)vc;

@property (strong, nonatomic) FBSession *session;

-(void)resetView;
@end

