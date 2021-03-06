//
//  AppDelegate.swift
//  Planck
//
//  Created by Lei Mingyu on 10/03/15.
//  Copyright (c) 2015 Echx. All rights reserved.
//

import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var drawerController: MMDrawerController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let settingViewController = SettingViewController.getInstance()
        
        // initialize the right scroll page view here
        let systemLevelSelectVC = LevelSelectViewController.getInstance()
        let userLevelSelectVC = CustomizedLevelSelectViewController.getInstance()
        let scrollPageArray = [systemLevelSelectVC, userLevelSelectVC]
        let scrollPageViewController = ScrollPageViewController.getInstance(scrollPageArray)
        let homeViewController = HomeViewController.getInstance()
        
        // initialize the drawer view controllers
        self.drawerController = MMDrawerController(centerViewController: homeViewController,
                                                    leftDrawerViewController: settingViewController,
                                                    rightDrawerViewController: scrollPageViewController)
        
        self.drawerController!.maximumLeftDrawerWidth = Constant.leftDrawerWidth
        self.drawerController!.maximumRightDrawerWidth = Constant.rightDrawerWidth
        self.drawerController!.openDrawerGestureModeMask = MMOpenDrawerGestureMode.All
        self.drawerController!.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.PanningCenterView
                                                            | MMCloseDrawerGestureMode.TapCenterView
        self.drawerController?.shouldStretchDrawer = false
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = self.drawerController
        
        // initialize the storage folder
        StorageManager.defaultManager.initStorage()
        if !GameStats.isNotFirstTime() {
            // load the predefined levels when the first time play the game
            StorageManager.defaultManager.copyGameLevels()
        }
        StorageManager.defaultManager.setNeedsReload()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

