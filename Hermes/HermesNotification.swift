import UIKit

protocol HermesNotificationDelegate: class {
    func notificationDidChangeAutoClose(_ notification: HermesNotification)
}

open class HermesNotification: NSObject {
  weak var delegate: HermesNotificationDelegate?
  
  /// The text of the notification
  open var text: String? {
    set(text) {
      if (text != nil) {
        attributedText = NSAttributedString(string: text!)
      } else {
        attributedText = nil
      }
    }
    get {
      return attributedText?.string
    }
  }
  
  /// Text, but with fancy attributes instead of a regular `String`
  open var attributedText: NSAttributedString?
  
  /// The color of the bottom bar on the notification
  open var color: UIColor?
  
  /// The image to be displayed along with the notification
  open var image: UIImage?
  
  /// The URL to the image
  open var imageURL: URL?
  open var tag: String?
  
  /// The path to the sound to be played along with the notification
  open var soundPath: String?
  
  /// The code that should be executed when the notification is tapped on
  open var action: ((HermesNotification) -> Void)? = nil
  
  /// Should the notification close automatically?
  open var autoClose = true {
    didSet {
      if oldValue != autoClose {
        delegate?.notificationDidChangeAutoClose(self)
      }
    }
  }
  
  /// The time interval that the notification should stay on screen before self-dismissing
  open var autoCloseTimeInterval: TimeInterval = 3
  
  /// Force the notification to perform it's action
  open func invokeAction() {
    if action != nil {
      action!(self)
    }
  }
}
