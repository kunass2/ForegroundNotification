//
//  ForegroundNotification.swift
//  ForegroundNotification
//
//  Created by Bartłomiej Semańczyk on 26/09/15.
//  Copyright © 2015 Bartłomiej Semańczyk. All rights reserved.
//

@objc public protocol ForegroundNotificationDelegate: class, UIApplicationDelegate {

    @objc optional func foregroundRemoteNotificationWasTouched(with userInfo: [AnyHashable: Any])
    @objc optional func foregroundLocalNotificationWasTouched(with localNotification: UILocalNotification)
}

import UIKit
import AVFoundation

open class ForegroundNotification {
    
    private lazy var foregroundNotificationView: ForegroundNotificationView = {
        return UINib(nibName: "ForegroundNotificationView", bundle: Bundle(for: ForegroundNotificationView.classForCoder())).instantiate(withOwner: nil, options: nil).first as! ForegroundNotificationView
    }()
    
    open static var systemSoundID: SystemSoundID = 1001
    open static var timeToDismissNotification = 4
    
    open weak var delegate: ForegroundNotificationDelegate? {
        
        didSet {
            foregroundNotificationView.delegate = delegate
        }
    }
    
    static var pendingForegroundNotifications = [ForegroundNotification]()
    
    private var heightConstraintTextView: NSLayoutConstraint?
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    public init(userInfo: [AnyHashable: Any]) {
        foregroundNotificationView.userInfo = userInfo
    }
    
    public init(localNotification: UILocalNotification) {
        foregroundNotificationView.localNotification = localNotification
    }
    
    public init(title: String?, subtitle: String?, category: String?, soundName: String?, userInfo: [AnyHashable: Any]?, localNotification: UILocalNotification?) {
        
        foregroundNotificationView.titleLabel.text = title ?? ""
        foregroundNotificationView.subtitleTextView.text = subtitle ?? ""
        foregroundNotificationView.categoryIdentifier = category
        foregroundNotificationView.soundName = soundName
        
        foregroundNotificationView.userInfo = userInfo
        foregroundNotificationView.localNotification = localNotification
    }

    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    //MARK: - Open
    
    open func presentNotification() {
        
        foregroundNotificationView.setupNotification()

        ForegroundNotification.pendingForegroundNotifications.append(self)
        
        if ForegroundNotification.pendingForegroundNotifications.count == 1 {
            ForegroundNotification.pendingForegroundNotifications.first?.fire()
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
