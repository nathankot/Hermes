import UIKit

extension UIImageView {
  func h_setImage(url: URL) {
    // Using NSURLSession API to fetch image
    // TODO: maybe change NSURLConfiguration to add things like timeouts and cellular configuration
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)

    // NSURLRequest Object
    let request = URLRequest(url: url)

    let dataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
      if error == nil {
        // Set whatever image attribute to the returned data
        self.image = UIImage(data: data!)!
      } else {
        print(error)
      }
    } as! (Data?, URLResponse?, Error?) -> Void)

    // Start the data task
    dataTask.resume()
  }
}

class HermesDefaultNotificationView: HermesNotificationView {
  override var notification: HermesNotification? {
    didSet {
      textLabel.attributedText = notification?.attributedText
      imageView.backgroundColor = notification?.color
      colorView.backgroundColor = notification?.color
      imageView.image = notification?.image
      if let imageURL  = notification?.imageURL {
        imageView.h_setImage(url: imageURL as URL)
      }
      layoutSubviews()
    }
  }

  var style: HermesStyle = .dark {
    didSet {
      textLabel.textColor = style == .light ? .darkGray : .white
    }
  }

  fileprivate var imageView = UIImageView()
  fileprivate var textLabel = UILabel()
  fileprivate var colorView = UIView()

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    imageView.contentMode = .center
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 5
    textLabel.textColor = .white
    textLabel.font = UIFont(name: "HelveticaNeue", size: 14)
    textLabel.numberOfLines = 3
    addSubview(imageView)
    addSubview(textLabel)
    addSubview(colorView)
  }

  convenience init(notification: HermesNotification) {
    self.init(frame: CGRect.zero)
    self.notification = notification
  }

  override func layoutSubviews() {
    let margin: CGFloat = 4
    let colorHeight: CGFloat = 4

    imageView.isHidden = notification?.image == nil && notification?.imageURL == nil
    imageView.frame = CGRect(x: margin * 2, y: 0, width: 34, height: 34)
    imageView.center.y = bounds.midY - colorHeight

    let (_, rightRect) = bounds.divided(atDistance: imageView.frame.maxX, from: .minXEdge)

    let space: CGFloat = 20
    let constrainedSize = rightRect.insetBy(dx: (space + margin) * 0.5, dy: 0).size

    textLabel.frame.size = textLabel.sizeThatFits(constrainedSize)
    textLabel.frame.origin.x = imageView.frame.maxX + space
    textLabel.center.y = bounds.midY - colorHeight

    colorView.frame = CGRect(x: margin, y: bounds.size.height - colorHeight, width: bounds.size.width - 2 * margin, height: colorHeight)

    // This centers the text across the whole view, unless that would cause it to block the imageView
    textLabel.center.x = bounds.midX
    let leftBound = imageView.frame.maxX + space
    if textLabel.frame.origin.x < leftBound {
      textLabel.frame.origin.x = leftBound
    }
  }
}
