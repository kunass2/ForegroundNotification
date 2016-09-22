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
        
        case up
        case down
        case pull
        case none
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
    
    private var initialPanLocation = CGPoint.zero
    private var previousPanStatus = BSPanStatus.none
    private var extendingIsFinished = false
    
    private var topConstraintNotification: NSLayoutConstraint!
    private var heightConstraintNotification: NSLayoutConstraint!
    private var timerToDismissNotification: Timer?
    
    private var leftUserNotificationAction: UIUserNotificationAction?
    private var rightUserNotificationAction: UIUserNotificationAction?
    private var currentUserNotificationTextFieldAction: UIUserNotificationAction?
    
    private var currentHeightContainerLayoutConstraint: NSLayoutConstraint?
    
    private var initialHeightForNotification: CGFloat = 80
    private var shouldShowTextView: Bool {
        
        get {
            
            if #available(iOS 9.0, *) {
                return leftUserNotificationAction == nil && rightUserNotificationAction?.behavior == .textInput
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
    
    var userInfo: [AnyHashable: Any]? {
        
        didSet {
            
            if let payload = userInfo?["aps"] as? [AnyHashable: Any] {
                
                if let alertTitle = payload["alert"] as? String {
                    
                    titleLabel.text = Bundle.main.infoDictionary?["CFBundleName"] as? String
                    subtitleLabel.text = alertTitle
                    
                } else {
                    
                    titleLabel.text = (payload["alert"] as? [AnyHashable: Any])?["title"] as? String ?? ""
                    subtitleLabel.text = (payload["alert"] as? [AnyHashable: Any])?["body"] as? String ?? ""
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
    
    @IBAction func viewPanned(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        let panLocation = gestureRecognizer.location(in: superview)
        let velocity = gestureRecognizer.velocity(in: self)
        
        switch gestureRecognizer.state {
            
        case .began:
            
            initialPanLocation = panLocation
            
        case .changed:

            topConstraintNotification.constant =  min(-(initialPanLocation.y - panLocation.y), 0)
            
            previousPanStatus = velocity.y >= 0 ? .down : .up
            
            if panLocation.y >= frame.size.height - 20 && !extendingIsFinished {
                
                previousPanStatus = .pull
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
                
                gestureRecognizer.isEnabled = false
                gestureRecognizer.isEnabled = true
            }
            
        case .ended, .cancelled, .failed:

            if previousPanStatus == .up {
                
                dismissNotification()
                
            } else if previousPanStatus == .pull {
                
                presentView()
                
            } else {
                
                moveViewToTop()
            }
            
            previousPanStatus = .none
            initialPanLocation = CGPoint.zero
            
        default:
            ()
        }
    }
    
    @IBAction func viewTapped(_ sender: UITapGestureRecognizer) {
        
        if let userInfo = userInfo {
            
            delegate?.foregroundRemoteNotificationWasTouched?(with: userInfo)
            
        } else if let localNotification = localNotification {
            
            delegate?.foregroundLocalNotificationWasTouched?(with: localNotification)
        }
        
        dismissNotification()
    }
    
    @IBAction func leftActionButtonTapped(_ sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = leftUserNotificationAction?.behavior , behavior == .textInput {
                
                currentUserNotificationTextFieldAction = leftUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 50
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            if let userInfo = userInfo {
                
                delegate?.application?(UIApplication.shared, handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                
            } else if let localNotification = localNotification {
                
                delegate?.application?(UIApplication.shared, handleActionWithIdentifier: leftUserNotificationAction?.identifier ?? "", for: localNotification, completionHandler: {})
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func rightActionButtonTapped(_ sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = rightUserNotificationAction?.behavior , behavior == .textInput {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 50
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            if let userInfo = userInfo {
                
                delegate?.application?(UIApplication.shared, handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                
            } else if let localNotification = localNotification {
                
                delegate?.application?(UIApplication.shared, handleActionWithIdentifier: rightUserNotificationAction?.identifier ?? "", for: localNotification, completionHandler: {})
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        
        if !textView.text.characters.isEmpty {
            
            if let userInfo = userInfo {
                
                if #available(iOS 9.0, *) {
                    delegate?.application?(UIApplication.shared, handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", forRemoteNotification: userInfo, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
                }
                
            } else if let localNotification = localNotification {
                
                if #available(iOS 9.0, *) {
                    delegate?.application?(UIApplication.shared, handleActionWithIdentifier: currentUserNotificationTextFieldAction?.identifier ?? "", for: localNotification, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: textView.text], completionHandler: {})
                }
            }
            
            dismissNotification()
        }
    }
    
    @IBAction func actionButtonHighlighted(_ sender: UIButton) {
        
        tapGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = false
        sender.alpha = 0.2
    }
    
    @IBAction func actionButtonLeft(_ sender: UIButton) {
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        sender.alpha = 1
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    func setupNotification() {
        
        if let window = UIApplication.shared.keyWindow , !titleLabel.text!.isEmpty && !subtitleLabel.text!.isEmpty {
            
            window.windowLevel = UIWindowLevelStatusBar
            
            frame = CGRect(x: 0, y: -initialHeightForNotification, width: UIApplication.shared.windows.first!.bounds.size.width, height: initialHeightForNotification)
            layoutIfNeeded()
            
            clipsToBounds = true
            translatesAutoresizingMaskIntoConstraints = false
            
            window.addSubview(self)
            window.bringSubview(toFront: self)
            
            topConstraintNotification = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: window, attribute: .top, multiplier: 1, constant: -initialHeightForNotification)
            heightConstraintNotification = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: initialHeightForNotification)
            
            let leadingConstraint = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: window, attribute: .leading, multiplier: 1, constant: 0)
            let trailingConstraint = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: window, attribute: .trailing, multiplier: 1, constant: 0)
            
            window.addConstraints([topConstraintNotification, leadingConstraint, trailingConstraint])
            addConstraint(heightConstraintNotification)
            
            setupActions()
        }
    }
    
    func presentNotification() {
        
        timerToDismissNotification = Timer.scheduledTimer(timeInterval: TimeInterval(BSForegroundNotification.timeToDismissNotification), target: self, selector: #selector(dismissNotification), userInfo: nil, repeats: false)
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.topConstraintNotification.constant = 0
            self.layoutIfNeeded()
        }) 
        
        if let soundName = soundName {
            
            let componentsFromSoundName = soundName.components(separatedBy: ".")
            
            if let soundTitle = componentsFromSoundName.first, let soundExtension = componentsFromSoundName.last, let soundPath = Bundle.main.path(forResource: soundTitle, ofType: soundExtension) {
                
                var soundID: SystemSoundID = 0
                
                AudioServicesCreateSystemSoundID(URL(fileURLWithPath: soundPath) as CFURL , &soundID)
                AudioServicesPlaySystemSound(soundID)
                
            } else {
                AudioServicesPlaySystemSound(BSForegroundNotification.systemSoundID)
            }
        }
    }
    
    func dismissNotification() {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = -self.heightConstraintNotification.constant
            self.layoutIfNeeded()
            
            }, completion: { finished in
                
                self.removeFromSuperview()
                
                if let _ = BSForegroundNotification.pendingForegroundNotifications.first {
                    BSForegroundNotification.pendingForegroundNotifications.removeFirst()
                }
                
                BSForegroundNotification.pendingForegroundNotifications.first?.fire()
                
                if BSForegroundNotification.pendingForegroundNotifications.isEmpty {
                    UIApplication.shared.delegate?.window??.windowLevel = UIWindowLevelNormal
                }
        })
    }
    
    //MARK: - Private
    
    fileprivate func setupActions() {
        
        heightTextContainerLayoutConstraint.constant = 0
        heightSingleButtonLayoutConstraint.constant = 0
        heightDoubleButtonsLayoutConstraint.constant = 0
        
        separatorView.alpha = 0
        leftActionButton.alpha = 0
        rightActionButton.alpha = 0
        singleActionButton.alpha = 0
        textView.alpha = 0
        sendButton.alpha = 0
        
        if let actions = UIApplication.shared.currentUserNotificationSettings?.categories?.filter({ return $0.identifier == categoryIdentifier }).first?.actions(for: .default) , actions.count > 0 {
            
            separatorView.alpha = 0.2
            rightUserNotificationAction = actions[0]
            leftUserNotificationAction = actions.count >= 2 ? actions[1] : nil
            
            leftActionButton.setTitle(leftUserNotificationAction?.title, for: UIControlState())
            rightActionButton.setTitle(rightUserNotificationAction?.title, for: UIControlState())
            singleActionButton.setTitle(rightUserNotificationAction?.title, for: UIControlState())
            
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
    
    fileprivate func presentView() {
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
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
    
    fileprivate func moveViewToTop() {
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = 0
            self.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    fileprivate func updateNotificationHeightWithNewTextViewHeight(_ height: CGFloat) {
        
        UIView.animate(withDuration: 0.4, animations: {
            
            self.heightTextContainerLayoutConstraint?.constant = height
            self.heightConstraintNotification.constant = self.maxHeightOfNotification + height - 50
            
            self.layoutIfNeeded()
        }) 
    }
    
    fileprivate func heightForText(_ text: String, width: CGFloat) -> CGFloat {
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = text
        
        label.sizeToFit()
        
        return label.frame.height
    }
    
    //MARK: - Overridden
    
    //MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        
        let isEmpty = textView.text.characters.isEmpty
        
        sendButton.alpha = isEmpty ? 0.2 : 1
        
        if isEmpty {
            updateNotificationHeightWithNewTextViewHeight(50)
        } else {
            updateNotificationHeightWithNewTextViewHeight(max(textView.contentSize.height + 20, 50))
        }
    }
}
