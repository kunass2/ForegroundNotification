//
//  BSForegroundNotificationView.swift
//  Pods
//
//  Created by Bartłomiej Semańczyk on 26/08/16.
//
//

import AVFoundation

class BSForegroundNotificationView: UIView, UITextViewDelegate {
    
    private enum BSPanStatus {
        
        case Up
        case Down
        case Pull
        case None
    }
    
    @IBOutlet private var heightTextContainerLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private var heightDoubleButtonsLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private var heightSingleButtonLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet private var appIconImageView: UIImageView!
    @IBOutlet private var separatorView: UIView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var textView: UITextView!
    
    @IBOutlet private var leftActionButton: UIButton!
    @IBOutlet private var rightActionButton: UIButton!
    @IBOutlet private var singleActionButton: UIButton!
    @IBOutlet private var sendButton: UIButton!
    
    @IBOutlet private var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet private var tapGestureRecognizer: UITapGestureRecognizer!
    
    private var initialPanLocation = CGPointZero
    private var previousPanStatus = BSPanStatus.None
    private var extendingIsFinished = false
    
    private var topConstraintNotification: NSLayoutConstraint!
    private var heightConstraintNotification: NSLayoutConstraint!
    private var timerToDismissNotification: NSTimer?
    
    private var leftUserNotificationAction: UIUserNotificationAction?
    private var rightUserNotificationAction: UIUserNotificationAction?
    private var currentUserNotificationTextFieldAction: UIUserNotificationAction?
    
    private var currentHeightContainerLayoutConstraint: NSLayoutConstraint?
    
    private var initialHeightForNotification: CGFloat = 80
    private var shouldShowTextView: Bool {
        
        get {
            
            if #available(iOS 9.0, *) {
                return leftUserNotificationAction == nil && rightUserNotificationAction?.behavior == .TextInput
            } else {
                return false
            }
        }
    }
    
    private var maxHeightOfNotification: CGFloat {
        
        get {
            
            var height = heightForText(subtitleLabel.text ?? "", width: subtitleLabel.frame.size.width) + 65
            
            if let _ = currentHeightContainerLayoutConstraint {
                height += 50
            }
            
            return height
        }
    }
    
    weak var delegate: BSForegroundNotificationDelegate?
    
    var categoryIdentifier: String?
    var soundName: String?
    
    var userInfo: [NSObject: AnyObject]? {
        
        didSet {
            
            if let payload = userInfo?["aps"] as? NSDictionary {
                
                if let alertTitle = payload["alert"] as? String {
                    
                    titleLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? String
                    subtitleLabel.text = alertTitle
                    
                } else {
                    
                    titleLabel.text = payload["alert"]?["title"] as? String ?? ""
                    subtitleLabel.text = payload["alert"]?["body"] as? String ?? ""
                }
                
                categoryIdentifier = payload["category"] as? String
                soundName = payload["sound"] as? String
            }
        }
    }
    
    var localNotification: UILocalNotification? {
        
        didSet {
            
            if #available(iOS 8.2, *) {
                
                titleLabel.text = localNotification?.alertTitle ?? ""
                
            } else {
                
                titleLabel.text = ""
            }
            
            subtitleLabel.text = localNotification?.alertBody ?? ""
            categoryIdentifier = localNotification?.category
            soundName = localNotification?.soundName
        }
    }
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appIconImageView.image = UIImage(named: "AppIcon40x40")
    }
    
    //MARK: - Deinitialization
    
    //MARK: - Actions
    
    @IBAction func viewPanned(gestureRecognizer: UIPanGestureRecognizer) {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        let panLocation = gestureRecognizer.locationInView(superview)
        let velocity = gestureRecognizer.velocityInView(self)
        
        switch gestureRecognizer.state {
            
        case .Began:
            
            initialPanLocation = panLocation
            
        case .Changed:

            topConstraintNotification.constant =  min(-(initialPanLocation.y - panLocation.y), 0)
            
            previousPanStatus = velocity.y >= 0 ? .Down : .Up
            
            if panLocation.y >= frame.size.height - 20 && !extendingIsFinished {
                
                previousPanStatus = .Pull
                heightConstraintNotification.constant = max(min(panLocation.y + 17, maxHeightOfNotification), initialHeightForNotification)
                
                if maxHeightOfNotification - frame.size.height <= 20 {
                    
                    let alpha = (20 - (maxHeightOfNotification - frame.size.height)) / 20
                    
                    leftActionButton.alpha = alpha
                    rightActionButton.alpha = alpha
                    singleActionButton.alpha = alpha
                    textView.alpha = alpha
                    sendButton.alpha = alpha / 5
                    currentHeightContainerLayoutConstraint?.constant = 50 - (maxHeightOfNotification - frame.size.height)
                }
            }
            
            if maxHeightOfNotification == heightConstraintNotification.constant && !extendingIsFinished {
                
                extendingIsFinished = true
                
                gestureRecognizer.enabled = false
                gestureRecognizer.enabled = true
            }
            
        case .Ended, .Cancelled, .Failed:

            if previousPanStatus == .Up {
                
                dismissNotification()
                
            } else if previousPanStatus == .Pull {
                
                presentView()
                
            } else {
                
                moveViewToTop()
            }
            
            previousPanStatus = .None
            initialPanLocation = CGPointZero
            
        default:
            ()
        }
    }
    
    @IBAction func viewTapped(sender: UITapGestureRecognizer) {
        
        if let userInfo = userInfo {
            
            delegate?.foregroundRemoteNotificationWasTouched?(userInfo)
            
        } else if let localNotification = localNotification {
            
            delegate?.foregroundLocalNotificationWasTouched?(localNotification)
        }
        
        dismissNotification()
    }
    
    @IBAction func leftActionButtonTapped(sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = leftUserNotificationAction?.behavior where behavior == .TextInput {
                
                currentUserNotificationTextFieldAction = leftUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 50
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            if let userInfo = userInfo {
                
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                
            } else if let localNotification = localNotification {
                
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", forLocalNotification: localNotification, completionHandler: {})
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func rightActionButtonTapped(sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = rightUserNotificationAction?.behavior where behavior == .TextInput {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 50
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            if let userInfo = userInfo {
                
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                
            } else if let localNotification = localNotification {
                
                delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", forLocalNotification: localNotification, completionHandler: {})
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func sendButtonTapped(sender: UIButton) {
        
        if !textView.text.characters.isEmpty {
            
            if let userInfo = userInfo {
                
                if #available(iOS 9.0, *) {
                    delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", forRemoteNotification: userInfo, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
                }
                
            } else if let localNotification = localNotification {
                
                if #available(iOS 9.0, *) {
                    delegate?.application?(UIApplication.sharedApplication(), handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", forLocalNotification: localNotification, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
                }
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func actionButtonHighlighted(sender: UIButton) {
        
        tapGestureRecognizer.enabled = false
        panGestureRecognizer.enabled = false
        sender.alpha = 0.2
    }
    
    @IBAction func actionButtonLeft(sender: UIButton) {
        
        tapGestureRecognizer.enabled = true
        panGestureRecognizer.enabled = true
        sender.alpha = 1
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    func setupNotification() {
        
        if let window = UIApplication.sharedApplication().keyWindow where !titleLabel.text!.isEmpty && !subtitleLabel.text!.isEmpty {
            
            window.windowLevel = UIWindowLevelStatusBar
            
            frame = CGRectMake(0, -initialHeightForNotification, UIApplication.sharedApplication().windows.first!.bounds.size.width, initialHeightForNotification)
            layoutIfNeeded()
            
            clipsToBounds = true
            translatesAutoresizingMaskIntoConstraints = false
            
            window.addSubview(self)
            window.bringSubviewToFront(self)
            
            topConstraintNotification = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: window, attribute: .Top, multiplier: 1, constant: -initialHeightForNotification)
            heightConstraintNotification = NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: initialHeightForNotification)
            
            let leadingConstraint = NSLayoutConstraint(item: self, attribute: .Leading, relatedBy: .Equal, toItem: window, attribute: .Leading, multiplier: 1, constant: 0)
            let trailingConstraint = NSLayoutConstraint(item: self, attribute: .Trailing, relatedBy: .Equal, toItem: window, attribute: .Trailing, multiplier: 1, constant: 0)
            
            window.addConstraints([topConstraintNotification, leadingConstraint, trailingConstraint])
            addConstraint(heightConstraintNotification)
            
            setupActions()
        }
    }
    
    func presentNotification() {
        
        timerToDismissNotification = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(BSForegroundNotification.timeToDismissNotification), target: self, selector: #selector(dismissNotification), userInfo: nil, repeats: false)
        
        UIView.animateWithDuration(0.5) {
            
            self.topConstraintNotification.constant = 0
            self.layoutIfNeeded()
        }
        
        if let soundName = soundName {
            
            let componentsFromSoundName = soundName.componentsSeparatedByString(".")
            
            if let soundTitle = componentsFromSoundName.first, let soundExtension = componentsFromSoundName.last, let soundPath = NSBundle.mainBundle().pathForResource(soundTitle, ofType: soundExtension) {
                
                var soundID: SystemSoundID = 0
                
                AudioServicesCreateSystemSoundID(NSURL(fileURLWithPath: soundPath) , &soundID)
                AudioServicesPlaySystemSound(soundID)
                
            } else {
                AudioServicesPlaySystemSound(BSForegroundNotification.systemSoundID)
            }
        }
    }
    
    func dismissNotification() {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = -self.heightConstraintNotification.constant
            self.layoutIfNeeded()
            
            }, completion: { finished in
                
                self.removeFromSuperview()
                
                if let _ = BSForegroundNotification.pendingForegroundNotifications.first {
                    BSForegroundNotification.pendingForegroundNotifications.removeFirst()
                }
                
                BSForegroundNotification.pendingForegroundNotifications.first?.fire()
                
                if BSForegroundNotification.pendingForegroundNotifications.isEmpty {
                    UIApplication.sharedApplication().delegate?.window??.windowLevel = UIWindowLevelNormal
                }
        })
    }
    
    //MARK: - Private
    
    private func setupActions() {
        
        heightTextContainerLayoutConstraint.constant = 0
        heightSingleButtonLayoutConstraint.constant = 0
        heightDoubleButtonsLayoutConstraint.constant = 0
        
        separatorView.alpha = 0
        leftActionButton.alpha = 0
        rightActionButton.alpha = 0
        singleActionButton.alpha = 0
        textView.alpha = 0
        sendButton.alpha = 0
        
        if let actions = UIApplication.sharedApplication().currentUserNotificationSettings()?.categories?.filter({ return $0.identifier == categoryIdentifier }).first?.actionsForContext(.Default) where actions.count > 0 {
            
            separatorView.alpha = 0.2
            rightUserNotificationAction = actions[0]
            leftUserNotificationAction = actions.count >= 2 ? actions[1] : nil
            
            leftActionButton.setTitle(leftUserNotificationAction?.title, forState: .Normal)
            rightActionButton.setTitle(rightUserNotificationAction?.title, forState: .Normal)
            singleActionButton.setTitle(rightUserNotificationAction?.title, forState: .Normal)
            
            if shouldShowTextView {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
                currentHeightContainerLayoutConstraint = heightTextContainerLayoutConstraint
                
            } else if leftUserNotificationAction != nil {
                
                currentHeightContainerLayoutConstraint = heightDoubleButtonsLayoutConstraint
                
            } else if rightUserNotificationAction != nil {
                
                currentHeightContainerLayoutConstraint = heightSingleButtonLayoutConstraint
            }
        }
    }
    
    private func presentView() {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
            
            self.heightConstraintNotification.constant = self.maxHeightOfNotification
            self.leftActionButton.alpha = 1
            self.rightActionButton.alpha = 1
            self.singleActionButton.alpha = 1
            self.textView.alpha = 1
            self.sendButton.alpha = 0.2
            self.currentHeightContainerLayoutConstraint?.constant = 50
            
            self.layoutIfNeeded()
            
            }, completion: { _ in
                
                self.extendingIsFinished = true
                
                if self.shouldShowTextView {
                    self.textView.becomeFirstResponder()
                }
        })
    }
    
    private func moveViewToTop() {
        
        UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = 0
            self.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    private func updateNotificationHeightWithNewTextViewHeight(height: CGFloat) {
        
        UIView.animateWithDuration(0.4) {
            
            self.heightTextContainerLayoutConstraint?.constant = height
            self.heightConstraintNotification.constant = self.maxHeightOfNotification + height - 50
            
            self.layoutIfNeeded()
        }
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
    
    //MARK: - Overridden
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        
        let isEmpty = textView.text.characters.isEmpty
        
        sendButton.alpha = isEmpty ? 0.2 : 1
        
        if isEmpty {
            updateNotificationHeightWithNewTextViewHeight(50)
        } else {
            updateNotificationHeightWithNewTextViewHeight(max(textView.contentSize.height + 20, 50))
        }
    }
}
