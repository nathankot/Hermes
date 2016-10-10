import UIKit

open class HermesNotificationView: UIView {
  open var notification: HermesNotification?
  let contentView = UIView()
    
  required public init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(contentView)
  }
  
  open override func layoutSubviews() {
    let margin: CGFloat = 8
    contentView.frame = CGRect(x: margin, y: 0, width: bounds.size.width - 2 * margin, height: bounds.size.height - margin)
  }
}
