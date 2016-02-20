# BSForegroundNotification

![Notification with text field action](Assets/1.png)
![Notification with button actions](Assets/2.png)
![Notification without actions](Assets/4.png)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

BSForegroundNotification is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BSForegroundNotification"
```

If you used `use_framework` in your podfile just simply do:

```Swift
import BSForegroundNotification

```

for every file when you need to use it.

you may also use:

```Swift
@import BSForegroundNotification

```
within **bridging header** file and avoid to import framework for every needed file.

##Info

- entirely written in latest Swift syntax. Works with iOS 8 and 9 and Xcode7.
- to present local foreground notification, both `alertTitle` and `alertBody` cannot be nil
- to present remote foreground notification, both `title` and `body` cannot be nil in `alert` dictionary. In case when `alert` is a string, that string cannot be empty.

##Usage

######Simply create your foreground notification object with on of three ways:

```Swift
let notification = BSForegroundNotification(userInfo: userInfo) //remote
let notification = BSForegroundNotification(localNotification: localNotification) //local
let notification = BSForegroundNotification(titleLabel: "title", subtitleLabel: "subtitle", categoryIdentifier: "category") //custom initializer
```

######Set a default dismissal time for the notification:

```Swift
notification.timeToDismissNotification = NSTimeInterval(10)
```

######Set delegate which conform to protocol `BSForegroundNotificationDelegate`:

Note that `BSForegroundNotificationDelegate` inherits from `UIApplicationsDelegate`

```Swift
notification.delegate = self
```

######Implement optional methods of `BSForegroundNotificationDelegate`


```Swift
@objc public protocol BSForegroundNotificationDelegate: class, UIApplicationDelegate {

    optional func foregroundRemoteNotificationWasTouched(userInfo: [NSObject: AnyObject])
    optional func foregroundLocalNotificationWasTouched(localNotifcation: UILocalNotification)
}
```

######Then present notification:

```Swift
notification.presentNotification()
```

######If it is needed one of `BSForegroundNotificationDelegate`'s method is called':

```Swift
func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void)
func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void)
func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void)
func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void)
```

######Class properties:

You can set your own sound using `systemSoundID` class property:

```BSForegroundNotification.systemSoundID = 1002 //1001 is by default```

## Author

Bartłomiej Semańczyk, bartekss2@icloud.com

## License

`BSForegroundNotification` is available under the MIT license. See the LICENSE file for more info.
