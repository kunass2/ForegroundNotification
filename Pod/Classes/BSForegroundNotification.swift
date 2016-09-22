//
//  BSForegroundNotification.swift
//  BSForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

@objc public protocol BSForegroundNotificationDelegate: class, UIApplicationDelegate {

    @objc optional func foregroundRemoteNotificationWasTouched(with userInfo: [AnyHashable: Any])
    @objc optional func foregroundLocalNotificationWasTouched(with localNotification: UILocalNotification)
}

import UIKit
import AVFoundation

open class BSForegroundNotification {
    
    private lazy var foregroundNotificationView: BSForegroundNotificationView = {
        return UINib(nibName: "BSForegroundNotificationView", bundle: Bundle(for: BSForegroundNotificationView.classForCoder())).instantiate(withOwner: nil, options: nil).first as! BSForegroundNotificationView
    }()
    
    open static var systemSoundID: SystemSoundID = 1001
    open static var timeToDismissNotification = 4
    
    open weak var delegate: BSForegroundNotificationDelegate? {
        
        didSet {
            foregroundNotificationView.delegate = delegate
        }
    }
    
    static var pendingForegroundNotifications = [BSForegroundNotification]()
    
    private var heightConstraintTextView: NSLayoutConstraint?
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    public init(userInfo: [AnyHashable: Any]) {
        foregroundNotificationView.userInfo = userInfo
    }
    
    public init(localNotification: UILocalNotification) {
        foregroundNotificationView.localNotification = localNotification
    }
    
    public init(titleLabel: String?, subtitleLabel: String?, categoryIdentifier: String?, soundName: String?, userInfo: [AnyHashable: Any]?, localNotification: UILocalNotification?) {
        
        foregroundNotificationView.titleLabel.text = titleLabel
        foregroundNotificationView.subtitleLabel.text = subtitleLabel
        foregroundNotificationView.categoryIdentifier = categoryIdentifier
        foregroundNotificationView.soundName = soundName
        
        foregroundNotificationView.userInfo = userInfo
        foregroundNotificationView.localNotification = localNotification
    }

    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    //MARK: - Open
    
    open func presentNotification() {
        
        foregroundNotificationView.setupNotification()

        BSForegroundNotification.pendingForegroundNotifications.append(self)
        
        if BSForegroundNotification.pendingForegroundNotifications.count == 1 {
            BSForegroundNotification.pendingForegroundNotifications.first?.fire()
        }
    }
    
    open func dismissView() {
        foregroundNotificationView.dismissNotification()
    }
    
    //MARK: - Internal
    
    func fire() {
        foregroundNotificationView.presentNotification()
    }

    //MARK: - Private
}
