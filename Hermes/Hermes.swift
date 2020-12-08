import UIKit
import AVFoundation

@objc public protocol HermesDelegate {
  /**
  - parameter hermes: the Hermes instance
  - parameter notification: the notification being made
  - returns: the notification view, or nil to use HermesDefaultNotificationView
  */
  @objc optional func hermesNotificationViewForNotification(hermes: Hermes, notification: HermesNotification) -> HermesNotificationView?
    
  /**
  - parameter hermes: the Hermes instance
  - parameter explicit: is true if the user closed the bulletin with their finger, instead of relying on autoclose
  - parameter notification: the notification that was showing when Hermes was closed
  */
  @objc optional func hermesDidClose(_ hermes: Hermes, explicit: Bool, notification: HermesNotification)
}

/**
Hermes is an in-app notification system that has a simple interface and can work with just about any sort of notification you can think of.
Examples include, but are not limited to:

- Success alerts
- Failure alerts
- Push Notifications
- Social Notifications (someone just commented on your post!)

Notes:

- Currently, this library only works well when you keep your app in one orientation.  Switching between portrait and landscape causes some gnarly
bugs and still needs to be handled.
*/

@objc public enum HermesStyle : Int {
    case dark, light
}

open class Hermes: NSObject, HermesBulletinViewDelegate {
  // MARK: - Public variables
  // MARK: - Singleton
  /**
  You typically will never need to use more than one instance of Hermes
  */
  public static let sharedInstance = Hermes()
  open var style: HermesStyle = .dark
    
  // MARK: -
  weak open var delegate: HermesDelegate?
    
  // MARK: - private variables
  fileprivate var bulletinView: HermesBulletinView?
  fileprivate var notifications = [HermesNotification]()
  
  var audioPlayer: AVAudioPlayer?

  /**
  When Hermes is waiting, he will collect all of your notifications. Use wait() and go() to tell Hermes when to collect and when to deliver notifications
  */
  fileprivate var waiting = false {
    didSet {
      if !waiting {
        showNotifications() 
      }
    }
  }
  
  // MARK: - Public methods
  
  /**
  Give Hermes one notification to post. If waiting == false, you'll see this notification right away
  
  - parameter notification: The notification you want Hermes to post
  */
  open func postNotification(_ notification: HermesNotification) {
    postNotifications([notification])
  }
  
  /**
  Give Hermes an array of notifications to post. If waiting == false, you'll see these notifications right away
  
  - parameter notifications: The notifications you want Hermes to post
  */
  open func postNotifications(_ notifications: [HermesNotification]) {
    self.notifications += notifications
    
    if let firstNotification = self.notifications.first {
      if firstNotification.soundPath != nil {
        prepareSound(path: firstNotification.soundPath!)
      }
    }
    
    showNotifications()
  }
  
  /**
  Tell Hermes to wait and you can queue up multiple notifications
  */
  open func wait() {
    waiting = true
  }
  
  /**
  Done queuing up those notifications? Tell Hermes to go!
  */
  open func go() {
    waiting = false
    showNotifications()
  }
  
  open func close() {
    bulletinView?.close(explicit: false)
  }
  
  open func containsNotification(_ notification: HermesNotification) -> Bool{
    if let bulletinView = self.bulletinView {
        return bulletinView.notifications.contains(notification)
    }
    return false
  }
    
  // MARK: - private methods
  
  /**
  This method will attempt to show all currently queued up notifications.  If Hermes has waiting set to true, 
  or if there are not notifications, this method will do nothing
  */
  fileprivate func showNotifications() {
    if waiting || notifications.count == 0 || bulletinView != nil {
      return
    }
    
    bulletinView = HermesBulletinView()
    
    switch style {
    case .dark:
        bulletinView!.style = .dark
    case .light:
        bulletinView!.style = .light
    }
    bulletinView!.delegate = self
    bulletinView!.notifications = notifications
    bulletinView!.show()
    audioPlayer?.play()
    
    notifications.removeAll(keepingCapacity: true) 
  }

  // Initial setup
  func prepareSound(path: String) {
    let sound = URL(fileURLWithPath: path)
    audioPlayer = try? AVAudioPlayer(contentsOf: sound)
    audioPlayer!.prepareToPlay()
  }
  
  // MARK: - HermesBulletinViewDelegate
  
  func bulletinViewDidClose(_ bulletinView: HermesBulletinView, explicit: Bool) {
    delegate?.hermesDidClose?(self, explicit: explicit, notification: bulletinView.currentNotification)
    self.bulletinView = nil
    showNotifications()
  }
  
  func bulletinViewNotificationViewForNotification(_ notification: HermesNotification) -> HermesNotificationView? {
    return delegate?.hermesNotificationViewForNotification?(hermes: self, notification: notification)
  }
}
