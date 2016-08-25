//
//  BSForegroundNotification.swift
//  BSForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

@objc public protocol BSForegroundNotificationDelegate: class, UIApplicationDelegate {

    optional func foregroundRemoteNotificationWasTouched(userInfo: [NSObject: AnyObject])
    optional func foregroundLocalNotificationWasTouched(localNotifcation: UILocalNotification)
}

import UIKit
import AVFoundation

public class BSForegroundNotification {
    
    private lazy var foregroundNotificationView: BSForegroundNotificationView = {
        return UINib(nibName: "BSForegroundNotificationView", bundle: NSBundle(forClass: BSForegroundNotificationView.classForCoder())).instantiateWithOwner(nil, options: nil).first as! BSForegroundNotificationView
    }()
    
    public static var systemSoundID: SystemSoundID = 1001
    public static var timeToDismissNotification = 4
    
    public weak var delegate: BSForegroundNotificationDelegate? {
        
        didSet {
            foregroundNotificationView.delegate = delegate
        }
    }
    
    static var pendingForegroundNotifications = [BSForegroundNotification]()
    
    private var heightConstraintTextView: NSLayoutConstraint?
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    public init(userInfo: [NSObject : AnyObject]) {
        foregroundNotificationView.userInfo = userInfo
    }
    
    public init(localNotification: UILocalNotification) {
        foregroundNotificationView.localNotification = localNotification
    }
    
    public init(titleLabel: String?, subtitleLabel: String?, categoryIdentifier: String?, soundName: String?, userInfo: [NSObject: AnyObject]?, localNotification: UILocalNotification?) {
        
        foregroundNotificationView.titleLabel.text = titleLabel
        foregroundNotificationView.subtitleLabel.text = subtitleLabel
        foregroundNotificationView.categoryIdentifier = categoryIdentifier
        foregroundNotificationView.soundName = soundName
        
        foregroundNotificationView.userInfo = userInfo
        foregroundNotificationView.localNotification = localNotification
    }

    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    //MARK: - Public
    
    public func presentNotification() {
        
        foregroundNotificationView.setupNotification()

        BSForegroundNotification.pendingForegroundNotifications.append(self)
        
        if BSForegroundNotification.pendingForegroundNotifications.count == 1 {
            BSForegroundNotification.pendingForegroundNotifications.first?.fire()
        }
    }
    
    public func dismissView() {
        foregroundNotificationView.dismissNotification()
    }
    
    //MARK: - Internal
    
    func fire() {
        foregroundNotificationView.presentNotification()
    }

    //MARK: - Private
}
