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

##Usage

######Simply create your foreground notification object with on of three ways:

```Swift
let notification = BSForegroundNotification(userInfo: userInfo) //remote
let notification = BSForegroundNotification(localNotification: localNotification) //local
let notification = BSForegroundNotification(titleLabel: "title", subtitleLabel: "subtitle", categoryIdentifier: "category") //custom initializer
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

## Author

Bartłomiej Semańczyk, bartekss2@icloud.com

## License

`BSForegroundNotification` is available under the MIT license. See the LICENSE file for more info.
