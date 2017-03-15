//
//  ForegroundNotificationView.swift
//  Pods
//
//  Created by Bartłomiej Semańczyk on 26/08/16.
//
//

import AVFoundation

class ForegroundNotificationView: UIView, UITextViewDelegate {
    
    private enum PanStatus {
        
        case up
        case down
        case pull
        case none
    }
    
    @IBOutlet private var heightTextContainerLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private var heightDoubleButtonsLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private var heightSingleButtonLayoutConstraint: NSLayoutConstraint!
    @IBOutlet private var heightPullViewLayoutConstraint: NSLayoutConstraint!
    
    @IBOutlet private var appIconImageView: UIImageView!
    
    @IBOutlet var applicationNameLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleTextView: UITextView!
    @IBOutlet var textView: UITextView!
    
    @IBOutlet private var leftActionButton: UIButton!
    @IBOutlet private var rightActionButton: UIButton!
    @IBOutlet private var singleActionButton: UIButton!
    @IBOutlet private var sendButton: UIButton!
    
    @IBOutlet private var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet private var tapGestureRecognizer: UITapGestureRecognizer!
    
    private var initialPanLocation = CGPoint.zero
    private var previousPanStatus = PanStatus.none
    private var extendingIsFinished = false
    
    private var topConstraintNotification: NSLayoutConstraint!
    private var heightConstraintNotification: NSLayoutConstraint!
    private var timerToDismissNotification: Timer?
    
    private var leftUserNotificationAction: UIUserNotificationAction?
    private var rightUserNotificationAction: UIUserNotificationAction?
    private var currentUserNotificationTextFieldAction: UIUserNotificationAction?
    
    private var currentHeightContainerLayoutConstraint: NSLayoutConstraint?
    
    private var dimmingView = UIView()
    
    private var shouldShowTextView: Bool {
        
        if #available(iOS 9.0, *) {
            return leftUserNotificationAction == nil && rightUserNotificationAction?.behavior == .textInput
        } else {
            return false
        }
    }
    
    private var heightForTitleAndSubtitleAndMargins: CGFloat {
        
        var height: CGFloat = 20 + 35 + 10
        height += titleLabel.text!.isEmpty ? 0 : 17
        height += subtitleTextView.text.isEmpty ? 0 : heightForText(subtitleTextView.text, width: currentWidthForSubtitle) + 22
        
        return height
    }
    
    private var initialHeightForNotification: CGFloat {
        
        var height: CGFloat = 20 + 35 + 10
        
        height += titleLabel.text!.isEmpty ? 0 : 17
        height += subtitleTextView.text.isEmpty ? 0 : min(heightForText(subtitleTextView.text, width: currentWidthForSubtitle) + 22, 34 + 22)
        
        if maxHeightForNotification > height {
            height += 12
        }
        
        return height
    }
    
    private var currentHeightForKeyboard: CGFloat = 0 {
        
        didSet {
            updateNotificationHeight()
        }
    }
    
    private var maxHeightForNotification: CGFloat {

        var height = heightForTitleAndSubtitleAndMargins
        
        if rightUserNotificationAction != nil {
            
            height += 45
            
            if !textView.text.characters.isEmpty {
                height += currentHeightForTextView - 45
            }
        }
        
        return min(height, UIApplication.shared.keyWindow!.bounds.size.height - currentHeightForKeyboard)
    }
    
    private var currentHeightForTextView: CGFloat {
        return max(textView.contentSize.height + 10, 45)
    }
    
    private var currentWidthForSubtitle: CGFloat {
        return min(UIApplication.shared.keyWindow!.bounds.size.width, 620) - 50
    }
    
    private var maxHeightForTextContainer: CGFloat {

        if UIApplication.shared.keyWindow!.bounds.size.height - currentHeightForKeyboard == maxHeightForNotification {
            
            if heightForTitleAndSubtitleAndMargins <= maxHeightForNotification / 2 {
                return maxHeightForNotification - heightForTitleAndSubtitleAndMargins
            } else {
                return min(currentHeightForTextView, (maxHeightForNotification / 2) - 20)
            }
            
        } else {
            return currentHeightForTextView
        }
    }
    
    weak var delegate: ForegroundNotificationDelegate?
    
    var categoryIdentifier: String?
    var soundName: String?
    
    var userInfo: [AnyHashable: Any]? {
        
        didSet {
            
            applicationNameLabel.text = (Bundle.main.infoDictionary?["CFBundleName"] as? String)?.uppercased()
            titleLabel.text = ""
            subtitleTextView.text = ""
            
            if let payload = userInfo?["aps"] as? [AnyHashable: Any] {
                
                if let alertTitle = payload["alert"] as? String {
                    
                    titleLabel.text = alertTitle
                    
                } else {
                    
                    titleLabel.text = (payload["alert"] as? [AnyHashable: Any])?["title"] as? String
                    subtitleTextView.text = (payload["alert"] as? [AnyHashable: Any])?["body"] as? String
                }
                
                categoryIdentifier = payload["category"] as? String
                soundName = payload["sound"] as? String
            }
        }
    }
    
    var localNotification: UILocalNotification? {
        
        didSet {
            
            applicationNameLabel.text = (Bundle.main.infoDictionary?["CFBundleName"] as? String)?.uppercased()
            
            if #available(iOS 8.2, *) {
                titleLabel.text = localNotification?.alertTitle ?? ""
            } else {
                titleLabel.text = ""
            }
            
            subtitleTextView.text = localNotification?.alertBody ?? ""
            categoryIdentifier = localNotification?.category
            soundName = localNotification?.soundName
        }
    }
    
    //MARK: - Class Methods
    
    //MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        appIconImageView.image = UIImage(named: "AppIcon40x40")
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }
    
    //MARK: - Deinitialization
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
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
                heightConstraintNotification.constant = max(min(panLocation.y + 17, maxHeightForNotification), initialHeightForNotification)
            }
            
            if maxHeightForNotification == heightConstraintNotification.constant && !extendingIsFinished {
                
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
        
        dismissNotification {
            
            if let userInfo = self.userInfo {
                
                self.delegate?.foregroundRemoteNotificationWasTouched?(with: userInfo)
                
            } else if let localNotification = self.localNotification {
                
                self.delegate?.foregroundLocalNotificationWasTouched?(with: localNotification)
            }
        }
    }
    
    @IBAction func leftActionButtonTapped(_ sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = leftUserNotificationAction?.behavior , behavior == .textInput {
                
                currentUserNotificationTextFieldAction = leftUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 45
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                updateNotificationHeight()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            dismissNotification {
                
                if let userInfo = self.userInfo {
                    
                    self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.leftUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                    
                } else if let localNotification = self.localNotification {
                    
                    self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.leftUserNotificationAction?.identifier ?? "", for: localNotification, completionHandler: {})
                }
            }
        }
    }
    
    @IBAction func rightActionButtonTapped(_ sender: UIButton) {
        
        var readyToDismiss = true
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        
        if #available(iOS 9.0, *) {
            
            if let behavior = rightUserNotificationAction?.behavior , behavior == .textInput {
                
                currentUserNotificationTextFieldAction = rightUserNotificationAction
                heightTextContainerLayoutConstraint.constant = 45
                heightDoubleButtonsLayoutConstraint.constant = 0
                textView.becomeFirstResponder()
                
                readyToDismiss = false
            }
        }
        
        if readyToDismiss {
            
            dismissNotification {
                
                if let userInfo = self.userInfo {
                    
                    self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.rightUserNotificationAction?.identifier ?? "", forRemoteNotification: userInfo, completionHandler: {})
                    
                } else if let localNotification = self.localNotification {
                    
                    self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.rightUserNotificationAction?.identifier ?? "", for: localNotification, completionHandler: {})
                }
            }
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        
        if !textView.text.characters.isEmpty {
            
            dismissNotification {
                
                if let userInfo = self.userInfo {
                    
                    if #available(iOS 9.0, *) {
                        self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.currentUserNotificationTextFieldAction?.identifier ?? "", forRemoteNotification: userInfo, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: self.textView.text], completionHandler: {})
                    }
                    
                } else if let localNotification = self.localNotification {
                    
                    if #available(iOS 9.0, *) {
                        self.delegate?.application?(UIApplication.shared, handleActionWithIdentifier: self.currentUserNotificationTextFieldAction?.identifier ?? "", for: localNotification, withResponseInfo: [UIUserNotificationActionResponseTypedTextKey: self.textView.text], completionHandler: {})
                    }
                }
            }
        }
    }
    
    @IBAction func actionButtonHighlighted(_ sender: UIButton) {
        
        tapGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = false
        sender.alpha = 0.9
    }
    
    @IBAction func actionButtonLeft(_ sender: UIButton) {
        
        tapGestureRecognizer.isEnabled = true
        panGestureRecognizer.isEnabled = true
        sender.alpha = 1
    }
    
    //MARK: - Public
    
    //MARK: - Internal
    
    func keyboardWillShow(notification: NSNotification) {
        currentHeightForKeyboard = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height ?? 0
    }
    
    func keyboardWillHide() {
        currentHeightForKeyboard = 0
    }
    
    func dimmingViewTapped(tapRecognizer: UITapGestureRecognizer) {
        dismissNotification()
    }
    
    func orientationDidChange() {
        
        if extendingIsFinished {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 as DispatchTime , execute: {
                
                UIView.animate(withDuration: 0.3) {
                    
                    self.heightConstraintNotification.constant = self.maxHeightForNotification
                    self.superview?.layoutIfNeeded()
                }
            })
        }
    }
    
    func setupNotification() {
        
        if let window = UIApplication.shared.keyWindow {
            
            setupActions()
            
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
        }
    }
    
    func presentNotification() {
        
        timerToDismissNotification = Timer.scheduledTimer(timeInterval: TimeInterval(ForegroundNotification.timeToDismissNotification), target: self, selector: #selector(dismissAfterTimer), userInfo: nil, repeats: false)
        
        UIView.animate(withDuration: 0.5, animations: {
            
            if self.maxHeightForNotification <= self.initialHeightForNotification {
                self.heightPullViewLayoutConstraint.constant = 0
            }
            
            self.heightTextContainerLayoutConstraint.constant = 0
            self.topConstraintNotification.constant = 0
            self.superview?.layoutIfNeeded()
        }) 
        
        if let soundName = soundName {
            
            let componentsFromSoundName = soundName.components(separatedBy: ".")
            
            if let soundTitle = componentsFromSoundName.first, let soundExtension = componentsFromSoundName.last, let soundPath = Bundle.main.path(forResource: soundTitle, ofType: soundExtension) {
                
                var soundID: SystemSoundID = 0
                
                AudioServicesCreateSystemSoundID(URL(fileURLWithPath: soundPath) as CFURL , &soundID)
                AudioServicesPlaySystemSound(soundID)
                
            } else {
                AudioServicesPlaySystemSound(ForegroundNotification.systemSoundID)
            }
        }
    }
    
    func dismissAfterTimer() {
        dismissNotification()
    }
    
    func dismissNotification(completion: (() -> ())? = nil) {
        
        timerToDismissNotification?.invalidate()
        timerToDismissNotification = nil
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = -self.heightConstraintNotification.constant
            self.dimmingView.alpha = 0
            self.superview?.layoutIfNeeded()
            
            }, completion: { finished in
                
                self.removeFromSuperview()
                self.dimmingView.removeFromSuperview()
                
                if let _ = ForegroundNotification.pendingForegroundNotifications.first {
                    ForegroundNotification.pendingForegroundNotifications.removeFirst()
                }
                
                ForegroundNotification.pendingForegroundNotifications.first?.fire()
                
                if ForegroundNotification.pendingForegroundNotifications.isEmpty {
                    UIApplication.shared.delegate?.window??.windowLevel = UIWindowLevelNormal
                }
                
                completion?()
        })
    }
    
    //MARK: - Private
    
    private func setupActions() {
        
        heightTextContainerLayoutConstraint.constant = 0
        heightSingleButtonLayoutConstraint.constant = 0
        heightDoubleButtonsLayoutConstraint.constant = 0
        
        leftActionButton.alpha = 0
        rightActionButton.alpha = 0
        singleActionButton.alpha = 0
        textView.alpha = 0
        sendButton.alpha = 0
        
        if let actions = UIApplication.shared.currentUserNotificationSettings?.categories?.filter({ return $0.identifier == categoryIdentifier }).first?.actions(for: .default) , actions.count > 0 {
            
            rightUserNotificationAction = actions[0]
            leftUserNotificationAction = actions.count >= 2 ? actions[1] : nil
            
            leftActionButton.setTitle(leftUserNotificationAction?.title, for: .normal)
            rightActionButton.setTitle(rightUserNotificationAction?.title, for: .normal)
            singleActionButton.setTitle(rightUserNotificationAction?.title, for: .normal)
            
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
    
    private func setupDimmingView() {
        
        let window = UIApplication.shared.keyWindow!
        
        dimmingView.frame = window.frame
        dimmingView.alpha = 0.01
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        dimmingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        
        visualEffectView.frame = dimmingView.bounds
        visualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        dimmingView.addSubview(visualEffectView)
        window.insertSubview(dimmingView, belowSubview: self)
    }
    
    private func presentView() {
        
        setupDimmingView()
        
        UIView.animate(withDuration: 0.2) {
            
            self.dimmingView.alpha = 1
            self.superview?.layoutIfNeeded()
        }
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
            self.heightConstraintNotification.constant = self.maxHeightForNotification
            self.leftActionButton.alpha = 1
            self.rightActionButton.alpha = 1
            self.singleActionButton.alpha = 1
            self.textView.alpha = 1
            self.sendButton.alpha = 1
            self.currentHeightContainerLayoutConstraint?.constant = 45
            self.heightPullViewLayoutConstraint.constant = 0
            
            self.superview?.layoutIfNeeded()
            
            }, completion: { _ in
                
                self.extendingIsFinished = true
                
                if self.shouldShowTextView {
                    self.textView.becomeFirstResponder()
                }
        })
    }
    
    private func moveViewToTop() {
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
            
            self.topConstraintNotification.constant = 0
            self.superview?.layoutIfNeeded()
        })
    }
    
    private func updateNotificationHeight() {
        
        var height = initialHeightForNotification
        
        if extendingIsFinished {
            height = maxHeightForNotification
        }
        
        UIView.animate(withDuration: 0.4, animations: {

            self.heightTextContainerLayoutConstraint?.constant = self.maxHeightForTextContainer
            self.heightConstraintNotification.constant = height
            
            self.superview?.layoutIfNeeded()
        })
    }
    
    private func heightForText(_ text: String?, width: CGFloat) -> CGFloat {
        
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
        updateNotificationHeight()
    }
}
