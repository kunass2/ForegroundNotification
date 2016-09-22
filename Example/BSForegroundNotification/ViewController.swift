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
    
    @IBAction func notificationWithTextFieldTapped(_ sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("TEXT_FIELD"))
        
        BSForegroundNotification.systemSoundID = 1000
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithTwoButtonsTapped(_ sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("TWO_BUTTONS"))
        
        BSForegroundNotification.systemSoundID = 1001
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithOneButtonTapped(_ sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory("ONE_BUTTON"))
        
        BSForegroundNotification.systemSoundID = 1003
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithoutActionsTapped(_ sender: UIButton) {
        
        let notification = BSForegroundNotification(userInfo: userInfoForCategory(""))
        
        BSForegroundNotification.systemSoundID = 1004
        notification.presentNotification()
        notification.delegate = self
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    //MARK: - Private
    
    fileprivate func userInfoForCategory(_ category: String) -> [AnyHashable: Any] {
        
        return ["aps": [
            "category": category,
            "alert": [
                "body": "Hello this is a big body, you can do this if you want. A very nice notification sis for you since now. available on GIthub for free. Is not this beautiful?:-)",
                "title": "Super notification title"
            ],
            "sound": "sound.wav"
            ]
        ]
    }
    
    //MARK: - Overridden
    
    //MARK: - BSForegroundNotificationDelegate
    
    func foregroundRemoteNotificationWasTouched(userInfo: [NSObject: AnyObject]) {
        responseLabel.text = "touched"
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        responseLabel.text = "action: \(identifier!)"
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        responseLabel.text = "textField: \(responseInfo[UIUserNotificationActionResponseTypedTextKey]!)"
    }
}
