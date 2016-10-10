import UIKit
import Hermes

class ViewController: UIViewController, HermesDelegate {
  let hermes = Hermes.sharedInstance

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    hermes.delegate = self

    let notification1 = HermesNotification()
    notification1.text = "Upload complete! Tap here to show an alert!"
    notification1.image = UIImage(named: "logo")
    notification1.color = .green
    notification1.action = { notification in
      let alert = UIAlertView(title: "Success", message: "Hermes notifications are actionable", delegate: nil, cancelButtonTitle: "Close")
      alert.show()
    }
    notification1.soundPath = Bundle.main.path(forResource: "notify", ofType: "wav")

    let notification2 = HermesNotification()

    let attributedText = NSMutableAttributedString(string: "Alan ")
    attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.lightGray, range: NSMakeRange(0, attributedText.length))
    attributedText.addAttribute(NSFontAttributeName , value: UIFont(name: "Helvetica-Bold", size: 14)!, range: NSMakeRange(0, attributedText.length))
    attributedText.append(NSAttributedString(string: "commented on your "))

    let imageText = NSMutableAttributedString(string: "image")
    imageText.addAttribute(NSForegroundColorAttributeName, value: UIColor.green, range: NSMakeRange(0, imageText.length))
    imageText.addAttribute(NSFontAttributeName, value: UIFont(name: "Helvetica-Bold", size: 15)!, range: NSMakeRange(0, imageText.length))

    attributedText.append(imageText)

    notification2.attributedText = attributedText
    notification2.image = UIImage(named: "logo")
    notification2.color = .red

    let notification3 = HermesNotification()
    notification3.text = "ATTN: There is a major update to your app!  Please go to the app store now and download it! Also, this message is purposely really long."
    notification3.image = UIImage(named: "logo")
    notification3.color = .yellow


    var delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      self.hermes.postNotifications([notification1, notification2, notification3, notification1, notification2, notification3])
    }

    delayTime = DispatchTime.now() + Double(Int64(4 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      self.hermes.postNotifications([notification1, notification2, notification3, notification1, notification2, notification3])
    }
  }

  // MARK: - HermesDelegate
  func hermesNotificationViewForNotification(hermes: Hermes, notification: HermesNotification) -> HermesNotificationView? {
    // You can create your own HermesNotificationView subclass and return it here :D (or return nil for the default notification view)
    return nil
  }
}
