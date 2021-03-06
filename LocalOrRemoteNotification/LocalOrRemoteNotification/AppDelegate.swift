//
//  AppDelegate.swift
//  LocalOrRemoteNotification
//
//  Created by wuweixin on 2019/7/1.
//  Copyright © 2019 wuweixin. All rights reserved.
//

import UIKit
import UserNotifications
#if DEBUG
import CocoaDebug
#endif

extension UIApplication.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active:
            return "active"
        case .background:
            return "background"
        case .inactive:
            return "inactive"
        @unknown default:
            return "unknown"
        }
    }
}

public func print<T>(file: String = #file, function: String = #function, line: Int = #line, _ message: T, color: UIColor = .white) {
    #if DEBUG
        swiftLog(file, function, line, message, color, false)
    #endif
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            CocoaDebug.enable()
        #endif
        // Override point for customization after application launch.
        registerNotifications()
        
        
        /// 注意：iOS以上通过通知启动应用，在launchOptions中有记录，然后UNUserNotificationCenterDelegate中的userNotificationCenter: didReceiveNotificationResponse:withCompletionHandler:也会调用，所以处理时要额外注意，防止重复处理
        if var remoteNotification = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            remoteNotification["from"] = "Launch Remote Notification"
            handleUserInfo(remoteNotification)
        }
        
        if var localNotification = launchOptions?[UIApplication.LaunchOptionsKey.localNotification] as? [AnyHashable: Any] {
            localNotification["from"] = "Launch Local Notification"
            handleUserInfo(localNotification)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}



// MARK: - Register & Unregister Notifications
extension AppDelegate {
    func registerNotifications() {
        registerRemoteNotifications()
    }
    
    
    func registerRemoteNotifications() {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if granted {
                    print("允许发送通知")
                } else {
                    print("不允许发送通知: \(error?.localizedDescription ?? "")")
                }
            }
            center.delegate = self
            UIApplication.shared.registerForRemoteNotifications()
        } else if #available(iOS 8.0, *) {
            let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(userSettings)
            UIApplication.shared.registerForRemoteNotifications()
        } else {
            UIApplication.shared.registerForRemoteNotifications(matching: [.alert, .sound, .badge])
        }
    }
    
    func registerLocalNotifications() {
        
    }
}


// MARK: - 注册推送回调
extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("didRegisterForRemoteNotificationsWithDeviceToken: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
}


// MARK: - iOS 10.0以下使用
extension AppDelegate {
    /*
     iOS 10.0之后废弃
     如果App在后台收到推送通知，则系统会进行提醒但不会调用该方法，需要用户手动点击通知栏中对应的通知进入app才能回调该方法。
     如果App在前台收到推送通知，则会直接回调该方法，但系统不会进行提醒
     
     API_DEPRECATED("使用UserNotifications框架的-[UNUserNotificationCenterDelegate willPresentNotification:withCompletionHandler:] 或 -[UNUserNotificationCenterDelegate didReceiveNotificationResponse:withCompletionHandler:] for user visible notifications and -[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:] for silent remote notifications", ios(3.0, 10.0))
    */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        var userInfo = userInfo
        userInfo["from"] = "didReceiveRemoteNotification"
        handleUserInfo(userInfo)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /*
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var userInfo = userInfo
        userInfo["from"] = "didReceiveRemoteNotification:fetchCompletionHandler:"
        handleUserInfo(userInfo)
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
    }
}

// MARK: - iOS 10.0以上使用
@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    /*
     有实现该方法：如果App在前台收到推送通知，则通知中心会直接调用该方法传递通知，我们可以根据需要更新我们App的内容。
     完成之后，调用completionHandler块，并指明通知用户的方式
     未实现该方法：则系统的行为就像您已将UNNotificationPresentationOptionNone选项传递给completionHandler块一样。
     如果您没有为UNUserNotificationCenter对象提供委托，系统将使用原始的通知方式(iOS 10.0以下)的来提醒用户。
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([]) // 在前台将不会弹窗通知
        completionHandler([.alert, .sound]) // 即使在前台也会alert提醒用户
    }
    
    /*
     使用此方法处理用户对通知的响应。 如果用户选择了App的自定义Action，则response参数包含该Action的标识符。
     （响应还可以指示用户在不选择自定义Action的情况下关闭了通知界面或启动了应用程序。）
     在实现结束时，调用completionHandler块让系统知道您已完成处理用户的响应。
     如果您未实施此方法，则您的应用永远不会响应自定义Action。
     
     iOS10.0及以上点击通知栏的通知启动应用也会调用该方法
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        center.removeAllDeliveredNotifications()
        var userInfo = response.notification.request.content.userInfo
        userInfo["from"] = "userNotificationCenter:didReceiveResponse"
        handleUserInfo(userInfo)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print("openSettingsForNotification")
    }
}


extension AppDelegate {
    func handleUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let vc = self.window?.rootViewController as? ViewController else {
            return
        }
        
        var userInfo = userInfo
        userInfo["applicationState"] = UIApplication.shared.applicationState.description
        
        if JSONSerialization.isValidJSONObject(userInfo) {
            do {
                let data = try JSONSerialization.data(withJSONObject: userInfo, options: [.fragmentsAllowed, .prettyPrinted])
                let jsonString = String(data: data, encoding: .utf8)
                if let text = vc.text {
                    vc.text = "\(text)\n\(jsonString ?? "")"
                } else {
                    vc.text = jsonString
                }
            } catch {
                print(error)
            }
        }
    }
}
