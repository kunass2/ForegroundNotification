//
//  ViewController.swift
//  BSForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

import UIKit
import BSForegroundNotification

class ViewController: UIViewController, BSForegroundNotificationDelegate {
    
    @IBOutlet var responseLabel: UILabel!
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    @IBAction func notificationWithTextFieldTapped(sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("TEXT_FIELD"))
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithTwoButtonsTapped(sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("TWO_BUTTONS"))
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithOneButtonTapped(sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("ONE_BUTTON"))
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithoutActionsTapped(sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory(""))
        notification.presentNotification()
        notification.delegate = self
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    //MARK: - Private
    
    private func userInfoForCategory(category: String) -> [NSObject: AnyObject] {
        
        return ["aps": [
            "category": category,
            "alert": [
                "body": "Hello this is a big body, you can do this if you want. A very nice notification sis for you since now. available on GIthub for free. Is not this beautiful?:-)",
                "title": "My first title"
            ],
            "sound": "anysound"
            ]
        ]
    }
    
    //MARK: - Overridden
    
    //MARK: - BSForegroundNotificationDelegate
    
    func foregroundRemoteNotificationWasTouched(userInfo: [NSObject : AnyObject]) {
        responseLabel.text = "touched"
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        responseLabel.text = "action: \(identifier!)"
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        responseLabel.text = "textField: \(responseInfo[UIUserNotificationActionResponseTypedTextKey]!)"
    }
}