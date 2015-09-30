//
//  AppDelegate.swift
//  BSForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

import UIKit
import BSForegroundNotification

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        registerNotifications()
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("new thing received")
    }
    
    private func registerNotifications() {
        
        let firstAction = UIMutableUserNotificationAction()
        firstAction.identifier = "first"
        firstAction.title = "FIRST"
        
        let secondAction = UIMutableUserNotificationAction()
        secondAction.identifier = "second"
        secondAction.title = "SECOND"
        
        let thirdAction = UIMutableUserNotificationAction()
        thirdAction.identifier = "third"
        thirdAction.title = "THIRD"
        
        let responseTextAction = UIMutableUserNotificationAction()
        responseTextAction.identifier = "text"
        responseTextAction.title = "New text"
        
        if #available(iOS 9.0, *) {
            responseTextAction.behavior = UIUserNotificationActionBehavior.TextInput
        }
        
        let twoButtonsCategory = UIMutableUserNotificationCategory()
        twoButtonsCategory.identifier = "TWO_BUTTONS"
        twoButtonsCategory.setActions([firstAction, responseTextAction], forContext: .Default)
        
        let textFieldCategory = UIMutableUserNotificationCategory()
        textFieldCategory.setActions([responseTextAction], forContext: .Default)
        textFieldCategory.identifier = "TEXT_FIELD"
        
        let oneButtonCategory = UIMutableUserNotificationCategory()
        oneButtonCategory.setActions([firstAction], forContext: .Default)
        oneButtonCategory.identifier = "ONE_BUTTON"
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge], categories: [twoButtonsCategory, oneButtonCategory, textFieldCategory])
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
}

