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

enum BSPanStatus {
    case Up
    case Down
    case Pull
    case None
}

import UIKit
import AVFoundation

public class BSForegroundNotification: UIView, UITextViewDelegate {
    
    public weak var delegate: BSForegroundNotificationDelegate?
    
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    private let vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: UIBlurEffect(style: .Dark)))
    
    private let appIconImageView = UIImageView(image: UIImage(named: "AppIcon40x40"))
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leftActionButton = UIButton()
    private let rightActionButton = UIButton()
    private let sendButton = UIButton()
    private let textView = UITextView()
    private let separatorView = UIView()
    
    private var userInfo: [NSObject: AnyObject]?
    private var localNotification: UILocalNotification?
    
    private var categoryIdentifier: String?
    private var sound: String?
    
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var leftUserNotificationAction: UIUserNotificationAction?
    private var rightUserNotificationAction: UIUserNotificationAction?
    private var currentUserNotificationTextFieldAction: UIUserNotificationAction?
    
    private var initialPanLocation = CGPointZero
    private var previousPanStatus = BSPanStatus.None
    private var extendingIsFinished = false
    
    private var topConstraintNotification: NSLayoutConstraint!
    private var heightConstraintNotification: NSLayoutConstraint!
    private var heightConstraintTextView: NSLayoutConstraint?
    
    private var timerToDismissNotification: NSTimer?
    
    private var maxHeightOfNotification: CGFloat {
        get {
            return heightForText(subtitleLabel.text ?? "", width: subtitleLabel.frame.size.width) + 65 + (heightConstraintTextView?.constant ?? 0)
        }
    }
    
    private var shouldShowTextView: Bool {
        get {
            if #available(iOS 9.0, *) {
                return leftUserNotificationAction == nil && rightUserNotificationAction?.behavior == .TextInput
            } else {
                return false
            }
        }
    }
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    public convenience init(userInfo: [NSObject : AnyObject]) {
        
        self.init(frame: CGRectZero)
        
        self.userInfo = userInfo
        
        if let payload = userInfo["aps"] as? NSDictionary {

            if let alertTitle = payload["alert"] as? String {
                titleLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String
                subtitleLabel.text = alertTitle
            } else {
                titleLabel.text = payload["alert"]?["title"] as? String ?? ""
                subtitleLabel.text = payload["alert"]?["body"] as? String ?? ""
            }
            
            categoryIdentifier = payload["category"] as? String
            sound = payload["sound"] as? String
        }
    }
    
    public convenience init(localNotification: UILocalNotification) {
        
        self.init(frame: CGRectZero)
        
        self.localNotification = localNotification
        
        titleLabel.text = localNotification.alertTitle ?? ""
        subtitleLabel.text = localNotification.alertBody ?? ""
        categoryIdentifier = localNotification.category
        sound = localNotification.soundName
    }
    
    public convenience init(titleLabel: String?, subtitleLabel: String?, categoryIdentifier: String?, soundName: String?, userInfo: [NSObject: AnyObject]?, localNotification: UILocalNotification?) {

        self.init(frame: CGRectZero)
        
        self.titleLabel.text = titleLabel
        self.subtitleLabel.text = subtitleLabel
        self.categoryIdentifier = categoryIdentifier
        self.sound = soundName
        
        self.userInfo = userInfo
        self.localNotification = localNotification
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("viewTapped"))
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("viewPanned"))
        
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    //MARK: - Public
    
    public func presentNotification() {

        if let window = UIApplication.sharedApplication().keyWindow where !titleLabel.text!.isEmpty && !subtitleLabel.text!.isEmpty {
            
            window.windowLevel = UIWindowLevelStatusBar
            window.addSubview(self)
            window.bringSubviewToFront(self)
            
            topConstraintNotification = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: window, attribute: .Top, multiplier: 1, constant: -80)
            heightConstraintNotification = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 80)
            
            let leadingConstraint = NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: window, attribute: .Leading, multiplier: 1, constant: 0)
            let trailingConstraint = NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: window, attribute: .Trailing, multiplier: 1, constant: 0)
            
            window.addConstraints([topConstraintNotification, leadingConstraint, trailingConstraint])
            addConstraint(heightConstraintNotification)
            
            setupBlurEffectView()
            setupIconImageView()
            setupLabels()
            setupVibrancyEffectView()
            setupButtonsAndTextView()
            setupActions()
            
            UIView.animateWithDuration(0.5) {
                self.topConstraintNotification.constant = 0
                self.layoutIfNeeded()
            }
            
            if let _ = sound {
                AudioServicesPlaySystemSound(1002)
            }
            
            timerToDismissNotification = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("dismissView"), userInfo: nil, repeats: false)
        }
    }
    
    //MARK: - Internal
    
    func viewTapped() {
        
        if let userInfo = userInfo {
            delegate?.foregroundRemoteNotificationWasTouched?(userInfo)
        } else if let localNotification = localNotification {
            delegate?.foregroundLocalNotificationWasTouched?(localNotification)
        }
        
        dismissView()
    }
    
    func viewPanned() {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        let panLocation = panGestureRecognizer.locationInView(superview)
        
        let velocity = panGestureRecognizer.velocityInView(self)
        
        switch panGestureRecognizer.state {
            
        case .Began:
            initialPanLocation = panLocation
        case .Changed:
            
            topConstraintNotification.constant =  min(-(initialPanLocation.y - panLocation.y), 0)
            
            previousPanStatus = velocity.y >= 0 ? .Down : .Up
            
            if panLocation.y >= frame.size.height - 20 && !extendingIsFinished {
                
                previousPanStatus = .Pull
                heightConstraintNotification.constant = max(min(panLocation.y + 17, maxHeightOfNotification), 70)
                
                if maxHeightOfNotification - frame.size.height <= 20 {
                    
                    let alpha = (20 - (maxHeightOfNotification - frame.size.height))/20
                    
                    leftActionButton.alpha = alpha
                    rightActionButton.alpha = alpha
                    
                    if shouldShowTextView {
                        textView.alpha = alpha
                        sendButton.alpha = alpha
                    }
                }
            }
            
            if maxHeightOfNotification == frame.size.height && !extendingIsFinished {

                extendingIsFinished = true
                
                leftActionButton.enabled = true
                rightActionButton.enabled = true
                sendButton.enabled = true
                textView.editable = true
                
                cancelPanGesture()
            }
            
        case .Ended, .Cancelled, .Failed:
            
            print(previousPanStatus)
            if previousPanStatus == .Up {
                print("dismissed")
                dismissView()
            } else if previousPanStatus == .Pull {
                print("pulled")
                presentView()
            } else {
                print("topped")
                moveViewToTop()
            }
            
            previousPanStatus = .None
            initialPanLocation = CGPointZero
            
        default:
            ()
        }
    }
    
    func leftActionButtonTapped(sender: UIButton) {
        
        var readyToDismiss = false
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        
        if #available(iOS 9.0, *) {
            if let behavior = leftUserNotificationAction?.behavior where behavior == .TextInput {
                currentUserNotificationTextFieldAction = leftUserNotificationAction
                presentTextField()
            } else {
                readyToDismiss = true
            }
        } else {
            readyToDismiss = true
        }
        
        if readyToDismiss {
            
            if let userInfo = userInfo {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
            } else if let localNotification = localNotification {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", forLocalNotification: localNotification, completionHandler: {})
            }
            dismissView()
        }
    }
    
    func rightActionButtonTapped(sender: UIButton) {
        
        var readyToDismiss = false
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        
        if #available(iOS 9.0, *) {
            if let behavior = rightUserNotificationAction?.behavior where behavior == .TextInput {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
                presentTextField()
            } else {
                readyToDismiss = true
            }
        } else {
            readyToDismiss = true
        }
        
        if readyToDismiss {
            
            
            if let userInfo = userInfo {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
            } else if let localNotification = localNotification {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", forLocalNotification: localNotification, completionHandler: {})
            }
            dismissView()
        }
    }
    
    func actionButtonHighlighted(sender: UIButton) {
        
        tapGestureRecognizer.enabled = false
        panGestureRecognizer.enabled = false
        sender.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.05)
    }
    
    func actionButtonLeft(sender: UIButton) {
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        sender.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
    }
    
    func sendButtonTapped(sender: UIButton) {
        
        if let userInfo = userInfo {
            
            if #available(iOS 9.0, *) {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", forRemoteNotification: userInfo, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
            }
        } else if let localNotification = localNotification {

            if #available(iOS 9.0, *) {
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", forLocalNotification: localNotification, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
            }
        }
        dismissView()
    }
    
    func dismissView() {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = -self.heightConstraintNotification.constant
            self.layoutIfNeeded()
            
            }, completion: { finished in
                
                self.removeFromSuperview()
                UIApplication.sharedApplication().delegate?.window??.windowLevel = UIWindowLevelNormal
        })
    }
    
    //MARK: - Private
    
    private func setupBlurEffectView() {

        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: blurEffectView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: blurEffectView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: blurEffectView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: blurEffectView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        
        addSubview(blurEffectView)
        addConstraints([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
        layoutIfNeeded()
    }
    
    private func setupIconImageView() {
        
        appIconImageView.translatesAutoresizingMaskIntoConstraints = false
        appIconImageView.contentMode = UIViewContentMode.ScaleAspectFill
        appIconImageView.layer.cornerRadius = 5
        appIconImageView.clipsToBounds = true
        
        let constraintTop = NSLayoutConstraint(item: appIconImageView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 10)
        let constraintLeading = NSLayoutConstraint(item: appIconImageView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 10)
        let constraintWidth = NSLayoutConstraint(item: appIconImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: 20)
        let constraintHeight = NSLayoutConstraint(item: appIconImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 20)
        
        appIconImageView.addConstraints([constraintWidth, constraintHeight])
        addSubview(appIconImageView)
        addConstraints([constraintTop, constraintLeading])
        layoutIfNeeded()
    }
    
    private func setupLabels() {
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFontOfSize(14)
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.sizeToFit()
        titleLabel.setContentCompressionResistancePriority(756, forAxis: .Vertical)
        titleLabel.setContentHuggingPriority(256, forAxis: .Vertical)
        
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFontOfSize(14)
        subtitleLabel.textColor = UIColor.whiteColor()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.sizeToFit()
        subtitleLabel.setContentCompressionResistancePriority(755, forAxis: .Vertical)
        subtitleLabel.setContentHuggingPriority(255, forAxis: .Vertical)
        
        let topConstraintTitleLabel = NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 10)
        let leadingConstraintTitleLabel = NSLayoutConstraint(item: titleLabel, attribute: .Leading, relatedBy: .Equal, toItem: appIconImageView, attribute: .Trailing, multiplier: 1, constant: 10)
        let trailingConstraintTitleLabel = NSLayoutConstraint(item: titleLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -10)
        
        let topConstraintSubtitleLabel = NSLayoutConstraint(item: subtitleLabel, attribute: .Top, relatedBy: .Equal, toItem: titleLabel, attribute: .Bottom, multiplier: 1, constant: 2)
        let trailingConstraintSubtitleLabel = NSLayoutConstraint(item: subtitleLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -10)
        let leadingEdgesTitleAndSubtitleLabel = NSLayoutConstraint(item: subtitleLabel, attribute: .Leading, relatedBy: .Equal, toItem: titleLabel, attribute: .Leading, multiplier: 1, constant: 0)
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addConstraints([topConstraintTitleLabel, leadingConstraintTitleLabel, trailingConstraintTitleLabel, topConstraintSubtitleLabel, trailingConstraintSubtitleLabel, leadingEdgesTitleAndSubtitleLabel])
        layoutIfNeeded()
    }
    
    private func setupVibrancyEffectView() {
        
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraintVibrancyEffectView = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Top, relatedBy: .Equal, toItem: subtitleLabel, attribute: .Bottom, multiplier: 1, constant: 10)
        let bottomConstraintVibrancyEffectView = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
        let leadingConstraintVibrancyEffectView = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        let trailingConstraintVibrancyEffectView = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        let minHeightVibrancyEffectView = NSLayoutConstraint(item: vibrancyEffectView, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Height, multiplier: 1, constant: 20)
        
        addSubview(vibrancyEffectView)
        vibrancyEffectView.addConstraint(minHeightVibrancyEffectView)
        addConstraints([topConstraintVibrancyEffectView, bottomConstraintVibrancyEffectView, leadingConstraintVibrancyEffectView, trailingConstraintVibrancyEffectView])
        
        separatorView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraintSeparatorView = NSLayoutConstraint(item: separatorView, attribute: .Top, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Top, multiplier: 1, constant: 0)
        let heightConstraintSeparatorView = NSLayoutConstraint(item: separatorView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 1)
        let leadingConstraintSeparatorView = NSLayoutConstraint(item: separatorView, attribute: .Leading, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Leading, multiplier: 1, constant: 0)
        let trailingConstraintSeparatorView = NSLayoutConstraint(item: separatorView, attribute: .Trailing, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Trailing, multiplier: 1, constant: 0)
        
        
        vibrancyEffectView.contentView.addSubview(separatorView)
        separatorView.addConstraint(heightConstraintSeparatorView)
        vibrancyEffectView.addConstraints([topConstraintSeparatorView, leadingConstraintSeparatorView, trailingConstraintSeparatorView])
        
        let bottomHandle = UIView()
        bottomHandle.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        bottomHandle.translatesAutoresizingMaskIntoConstraints = false
        bottomHandle.clipsToBounds = true
        bottomHandle.layer.cornerRadius = 2
        
        let widthConstraintBottomHandle = NSLayoutConstraint(item: bottomHandle, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: 50)
        let heightConstraintBottomHandle = NSLayoutConstraint(item: bottomHandle, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 4)
        let bottomConstraintBottomHandle = NSLayoutConstraint(item: bottomHandle, attribute: .Bottom, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Bottom, multiplier: 1, constant: -2)
        let centerHorizontalConstraintBottomHandle = NSLayoutConstraint(item: bottomHandle, attribute: .CenterX, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .CenterX, multiplier: 1, constant: 0)
        
        vibrancyEffectView.contentView.addSubview(bottomHandle)
        bottomHandle.addConstraints([widthConstraintBottomHandle, heightConstraintBottomHandle])
        vibrancyEffectView.addConstraints([bottomConstraintBottomHandle, centerHorizontalConstraintBottomHandle])
        layoutIfNeeded()
    }
    
    private func setupButtonsAndTextView() {
        
        leftActionButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        rightActionButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        textView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        
        leftActionButton.layer.cornerRadius = 3
        leftActionButton.clipsToBounds = true
        leftActionButton.titleLabel?.font = UIFont.systemFontOfSize(13)
        leftActionButton.addTarget(self, action: Selector("leftActionButtonTapped:"), forControlEvents: .TouchUpInside)
        leftActionButton.addTarget(self, action: Selector("actionButtonHighlighted:"), forControlEvents: .TouchDown)
        leftActionButton.addTarget(self, action: Selector("actionButtonLeft:"), forControlEvents: .TouchUpOutside)
        leftActionButton.setContentCompressionResistancePriority(757, forAxis: .Vertical)
        leftActionButton.alpha = 0
        leftActionButton.enabled = false
        
        rightActionButton.layer.cornerRadius = 3
        rightActionButton.clipsToBounds = true
        rightActionButton.titleLabel?.font = UIFont.systemFontOfSize(13)
        rightActionButton.addTarget(self, action: Selector("rightActionButtonTapped:"), forControlEvents: .TouchUpInside)
        rightActionButton.addTarget(self, action: Selector("actionButtonHighlighted:"), forControlEvents: .TouchDown)
        rightActionButton.addTarget(self, action: Selector("actionButtonLeft:"), forControlEvents: .TouchUpOutside)
        rightActionButton.setContentCompressionResistancePriority(757, forAxis: .Vertical)
        rightActionButton.alpha = 0
        rightActionButton.enabled = false
        
        textView.layer.cornerRadius = 3
        textView.clipsToBounds = true
        textView.textColor = UIColor.whiteColor()
        textView.alpha = 0
        textView.editable = false
        textView.delegate = self
        textView.font = UIFont.systemFontOfSize(14)
        
        sendButton.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
        sendButton.alpha = 0
        sendButton.enabled = false
        sendButton.addTarget(self, action: Selector("sendButtonTapped:"), forControlEvents: .TouchUpInside)
        
        leftActionButton.translatesAutoresizingMaskIntoConstraints = false
        rightActionButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    private func setupActions() {
        
        if let actions = UIApplication.sharedApplication().currentUserNotificationSettings()?.categories?.filter({ return $0.identifier == categoryIdentifier }).first?.actionsForContext(.Default) where actions.count > 0 {
            
            rightUserNotificationAction = actions[0]
            leftUserNotificationAction = actions.count >= 2 ? actions[1] : nil
            
            leftActionButton.setTitle(leftUserNotificationAction?.title, forState: .Normal)
            rightActionButton.setTitle(rightUserNotificationAction?.title, forState: .Normal)
            sendButton.setTitle("Send", forState: .Normal)
            
            heightConstraintTextView = NSLayoutConstraint(item: textView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 30)
            let leadingConstraintTextView = NSLayoutConstraint(item: textView, attribute: .Leading, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Leading, multiplier: 1, constant: 20)
            let topConstraintTextView = NSLayoutConstraint(item: textView, attribute: .Top, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Top, multiplier: 1, constant: 10)
            
            let heightConstraintSendButton = NSLayoutConstraint(item: sendButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 30)
            let widthConstraintSendButton = NSLayoutConstraint(item: sendButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1, constant: 40)
            let trailingConstraintSendButton = NSLayoutConstraint(item: sendButton, attribute: .Trailing, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Trailing, multiplier: 1, constant: -20)
            let bottomEdgeSendButton = NSLayoutConstraint(item: sendButton, attribute: .Bottom, relatedBy: .Equal, toItem: textView, attribute: .Bottom, multiplier: 1, constant: 0)
            let leadingConstraintSendButton = NSLayoutConstraint(item: sendButton, attribute: .Leading, relatedBy: .Equal, toItem: textView, attribute: .Trailing, multiplier: 1, constant: 20)
            
            vibrancyEffectView.contentView.addSubview(textView)
            vibrancyEffectView.contentView.addSubview(sendButton)
            
            textView.addConstraint(heightConstraintTextView!)
            sendButton.addConstraints([heightConstraintSendButton, widthConstraintSendButton])
            vibrancyEffectView.addConstraints([leadingConstraintTextView, topConstraintTextView, trailingConstraintSendButton, bottomEdgeSendButton, leadingConstraintSendButton])
            
            let topConstraintRightButton = NSLayoutConstraint(item: rightActionButton, attribute: .Top, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Top, multiplier: 1, constant: 10)
            let trailingConstraintRightButton = NSLayoutConstraint(item: rightActionButton, attribute: .Trailing, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Trailing, multiplier: 1, constant: -20)
            let heightConstraintRightButton = NSLayoutConstraint(item: rightActionButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 30)
            let leadingConstraintRightButton = NSLayoutConstraint(item: rightActionButton,
                attribute: .Leading,
                relatedBy: .Equal,
                toItem: leftUserNotificationAction != nil ? leftActionButton : vibrancyEffectView,
                attribute: leftUserNotificationAction != nil ? .Trailing : .Leading,
                multiplier: 1,
                constant: 20)
            
            if !shouldShowTextView {
                
                vibrancyEffectView.contentView.addSubview(rightActionButton)
                rightActionButton.addConstraint(heightConstraintRightButton)
            }

            if leftUserNotificationAction != nil {
                
                let equalWidthConstraintButtons = NSLayoutConstraint(item: rightActionButton, attribute: .Width, relatedBy: .Equal, toItem: leftActionButton, attribute: .Width, multiplier: 1, constant: 0)
                let equalHeightsConstraintButton = NSLayoutConstraint(item: rightActionButton, attribute: .Height, relatedBy: .Equal, toItem: leftActionButton, attribute: .Height, multiplier: 1, constant: 0)
                let topEdgesConstraintButtons = NSLayoutConstraint(item: rightActionButton, attribute: .Top, relatedBy: .Equal, toItem: leftActionButton, attribute: .Top, multiplier: 1, constant: 0)
                let leadingConstraintLeftButton = NSLayoutConstraint(item: leftActionButton, attribute: .Leading, relatedBy: .Equal, toItem: vibrancyEffectView, attribute: .Leading, multiplier: 1, constant: 20)
                
                vibrancyEffectView.contentView.addSubview(leftActionButton)
                vibrancyEffectView.addConstraints([equalWidthConstraintButtons, equalHeightsConstraintButton, topEdgesConstraintButtons, leadingConstraintLeftButton])
            }
            
            if !shouldShowTextView {
            
                vibrancyEffectView.addConstraints([topConstraintRightButton, trailingConstraintRightButton, leadingConstraintRightButton])
                layoutIfNeeded()
            }
            
            if shouldShowTextView {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
            }
            
        } else {
            separatorView.alpha = 0
        }
    }
    
    private func cancelPanGesture() {
        
        panGestureRecognizer.enabled = false
        panGestureRecognizer.enabled = true
    }
    
    private func presentView() {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
          
            self.heightConstraintNotification.constant = self.maxHeightOfNotification
            self.rightActionButton.alpha = 1
            self.leftActionButton.alpha = 1
            self.layoutIfNeeded()
            
            if self.shouldShowTextView {
                self.presentTextField()
            }
            
            }, completion: nil)
    }
    
    private func moveViewToTop() {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = 0
            self.layoutIfNeeded()
            }, completion: nil)
    }
    
    private func heightForText(text: String, width: CGFloat) -> CGFloat {
        
        let label = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        label.font = UIFont.systemFontOfSize(14)
        label.text = text
        
        label.sizeToFit()
        
        return label.frame.height
    }
    
    private func presentTextField() {
        
        UIView.animateWithDuration(0.2, animations: {
            
            self.textView.alpha = 1
            self.textView.editable = true
            self.sendButton.alpha = 1
            self.sendButton.enabled = true
            
            self.leftActionButton.alpha = 0
            self.rightActionButton.alpha = 0
            
            }) { finished in
                
                self.textView.becomeFirstResponder()
                self.leftActionButton.removeFromSuperview()
                self.rightActionButton.removeFromSuperview()
        }
    }
    
    private func updateNotificationHeightWithNewTextViewHeight(height: CGFloat) {
        
        UIView.animateWithDuration(0.4) {
            
            self.heightConstraintTextView?.constant = height
            self.heightConstraintNotification.constant = self.maxHeightOfNotification
            self.layoutIfNeeded()
        }
    }
    
    //MARK: - UITextViewDelegate
    
    public func textViewDidChange(textView: UITextView) {
        
        if textView.text.characters.isEmpty {
            updateNotificationHeightWithNewTextViewHeight(30)
        } else {
            updateNotificationHeightWithNewTextViewHeight(max(heightForText(textView.text, width: textView.frame.size.width - 10), 30) + 10)
        }
    }
}