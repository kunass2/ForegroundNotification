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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        registerNotifications()
        
        return true
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
            responseTextAction.behavior = UIUserNotificationActionBehavior.textInput
        }
        
        let twoButtonsCategory = UIMutableUserNotificationCategory()
        twoButtonsCategory.identifier = "TWO_BUTTONS"
        twoButtonsCategory.setActions([firstAction, responseTextAction], for: .default)
        
        let textFieldCategory = UIMutableUserNotificationCategory()
        textFieldCategory.setActions([responseTextAction], for: .default)
        textFieldCategory.identifier = "TEXT_FIELD"
        
        let oneButtonCategory = UIMutableUserNotificationCategory()
        oneButtonCategory.setActions([firstAction], for: .default)
        oneButtonCategory.identifier = "ONE_BUTTON"
        
        let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: [twoButtonsCategory, oneButtonCategory, textFieldCategory])
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
}

