//
//  ViewController.swift
//  BSForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

import UIKit
import ForegroundNotification

class ViewController: UIViewController, ForegroundNotificationDelegate {
    
    @IBOutlet var responseLabel: UILabel!
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    @IBAction func notificationWithTextFieldTapped(_ sender: UIButton) {
        
        let notification = ForegroundNotification(userInfo: userInfoForCategory("TEXT_FIELD"))
        
        ForegroundNotification.systemSoundID = 1000
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithTwoButtonsTapped(_ sender: UIButton) {
        
        let notification = ForegroundNotification(userInfo: userInfoForCategory("TWO_BUTTONS"))
        
        ForegroundNotification.systemSoundID = 1001
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithOneButtonTapped(_ sender: UIButton) {
        
        let notification = ForegroundNotification(userInfo: userInfoForCategory("ONE_BUTTON"))
        
        ForegroundNotification.systemSoundID = 1003
        notification.presentNotification()
        notification.delegate = self
    }
    
    @IBAction func notificationWithoutActionsTapped(_ sender: UIButton) {
        
        let notification = ForegroundNotification(userInfo: userInfoForCategory(""))
        
        ForegroundNotification.systemSoundID = 1004
        notification.delegate = self
        notification.presentNotification()
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    //MARK: - Private
    
    private func userInfoForCategory(_ category: String) -> [AnyHashable: Any] {
        
        return ["aps": [
            "category": category,
            "alert": [
                "body": "Hello this is a bigbody, you can do this if you want.",
                "title": "Super notification title"
            ],
            "sound": "sound.wav"
            ]
        ]
    }
    
    //MARK: - Overridden
    
    //MARK: - BSForegroundNotificationDelegate
    
    func foregroundRemoteNotificationWasTouched(with userInfo: [AnyHashable: Any]) {
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
