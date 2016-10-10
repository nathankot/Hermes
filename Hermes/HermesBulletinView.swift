import UIKit

protocol HermesBulletinViewDelegate: class {
  func bulletinViewDidClose(_ bulletinView: HermesBulletinView, explicit: Bool)
  func bulletinViewNotificationViewForNotification(_ notification: HermesNotification) -> HermesNotificationView?
}

let kMargin: CGFloat = 8
let kNotificationHeight: CGFloat = 98

class HermesBulletinView: UIView, UIScrollViewDelegate, HermesNotificationDelegate {
  weak var delegate: HermesBulletinViewDelegate?
  
  var currentNotification: HermesNotification {
    get {
      let page = pageFromOffset(scrollView.contentOffset)
      return notifications[page]
    }
  }
  
  let scrollView = UIScrollView()
  var backgroundView: UIVisualEffectView?
  
  var currentPage: Int = 0
  var timer: Timer?
  
  var notifications = [HermesNotification]() {
    didSet {
      for notification in notifications {
        notification.delegate = self
      }
      layoutNotifications()
    }
  }
  
  var tabView = UIView()
  var style: HermesStyle = .dark {
    didSet {
      switch style {
      case .light:
        blurEffectStyle = .extraLight
      case .dark:
        blurEffectStyle = .dark
      }
    }
  }
  fileprivate var blurEffectStyle: UIBlurEffectStyle = .dark {
    didSet {
      backgroundView?.removeFromSuperview()
      if blurEffectStyle == .dark {
        tabView.backgroundColor = UIColor(white: 1, alpha: 0.6)
      } else {
        tabView.backgroundColor = UIColor(white: 0, alpha: 0.1)
      }
      remakeBackgroundView()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HermesBulletinView.pan(_:)))
    addGestureRecognizer(panGestureRecognizer)
    
    remakeBackgroundView()
    
    scrollView.contentInset = UIEdgeInsetsMake(0, kMargin, 0, kMargin)
    scrollView.delegate = self
    
    addSubview(scrollView)
    addSubview(tabView)
  }
  
  fileprivate func remakeBackgroundView() {
    let blurEffect = UIBlurEffect(style: blurEffectStyle)
    backgroundView = UIVisualEffectView(effect: blurEffect)
    backgroundView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleTopMargin]
    insertSubview(backgroundView!, at: 0)
  }
  
  func pan(_ gesture: UIPanGestureRecognizer) {
    timer?.invalidate()
    var pan = gesture.translation(in: gesture.view!.superview!)
    let startFrame = bulletinFrameInView(gesture.view!.superview!)
    var frame = startFrame
    
    var dy: CGFloat = 0
    let height = gesture.view?.superview!.bounds.size.height
    let k = height! * 0.2
    if pan.y < 0 {
      pan.y = pan.y / k
      dy = k * pan.y / (sqrt(pan.y * pan.y + 1))
    } else {
      dy = pan.y
    }
    
    frame.origin.y += dy
    self.frame = frame
    
    if gesture.state == .ended {
      let layoutViewFrame = layoutViewFrameInView(gesture.view!.superview!)
      let velocity = gesture.velocity(in: gesture.view!.superview!)
      if dy > layoutViewFrame.size.height * 0.5 || velocity.y > 500{
        close(explicit: true)
      } else {
        animateIn()
      }
    }
  }
  
  func animateIn() {
    let bulletinFrame = bulletinFrameInView(self.superview!)
    
    UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
      self.frame = bulletinFrame
      }, completion: { completed in
        self.scheduleCloseTimer()
    })
    
  }
  
  func show(_ view: UIView = UIApplication.shared.windows[0], animated: Bool = true) {
    // Add to main queue in case the view loaded but wasn't added to the window yet.  This seems to happen in my storyboard test app
    DispatchQueue.main.async(execute: {
      view.addSubview(self)
      
      let bulletinFrame = self.bulletinFrameInView(self.superview!)
      var startFrame = bulletinFrame
      startFrame.origin.y += self.superview!.bounds.size.height
      
      self.frame = startFrame
      self.animateIn()
    })
  }
  
  func scheduleCloseTimer() {
    if currentNotification.autoClose {
      timer = Timer.scheduledTimer(timeInterval: currentNotification.autoCloseTimeInterval, target: self, selector: #selector(HermesBulletinView.nextPageOrClose), userInfo: nil, repeats: false)
    }
  }
  
  func close(explicit: Bool) {
    timer?.invalidate()
    
    isUserInteractionEnabled = false
    
    let startFrame = bulletinFrameInView(superview!)
    var offScreenFrame = startFrame
    offScreenFrame.origin.y = superview!.bounds.size.height
    
    UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
      self.frame = offScreenFrame
      }, completion: { completed in
        self.removeFromSuperview()
        self.isUserInteractionEnabled = true
        self.delegate?.bulletinViewDidClose(self, explicit: explicit)
    })
  }
  
  func contentOffsetForPage(_ page: Int) -> CGPoint {
    let boundsWidth = scrollView.bounds.size.width
    let pageWidth = boundsWidth - 2 * kMargin
    var contentOffset = CGPoint(x: pageWidth * CGFloat(page) - scrollView.contentInset.left, y: scrollView.contentOffset.y)
    if contentOffset.x < -scrollView.contentInset.left {
      contentOffset.x = -scrollView.contentInset.left
    } else if contentOffset.x + scrollView.contentInset.right + scrollView.bounds.size.width > scrollView.contentSize.width {
      contentOffset.x = scrollView.contentSize.width - scrollView.bounds.size.width + scrollView.contentInset.right
    }
    return contentOffset
  }
  
  func nextPageOrClose() {
    currentPage = pageFromOffset(scrollView.contentOffset)
    let boundsWidth = scrollView.bounds.size.width
    let pageWidth = boundsWidth - 2 * kMargin
    let totalPages = Int(scrollView.contentSize.width / pageWidth)
    
    if currentPage + 1 >= totalPages {
      close(explicit: false)
    } else {
      let newPage = currentPage + 1
      CATransaction.begin()
      scrollView.setContentOffset(contentOffsetForPage(newPage), animated: true)
      CATransaction.setCompletionBlock({
        self.scheduleCloseTimer()
      })
      CATransaction.commit()
    }
  }
  
  func bulletinFrameInView(_ view: UIView) -> CGRect {
    var bulletinFrame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height * 0.5)
    let notificationViewFrame = layoutViewFrameInView(view)
    
    bulletinFrame.origin = CGPoint(x: 0, y: view.bounds.size.height - notificationViewFrame.size.height)
    return bulletinFrame
  }
  
  func layoutViewFrameInView(_ view: UIView) -> CGRect {
    return CGRect(x: 0, y: 0, width: view.bounds.size.width, height: kNotificationHeight)
  }
  
  func notificationViewFrameInView(_ view: UIView) -> CGRect {
    var frame = layoutViewFrameInView(view)
    frame.origin.x += kMargin
    frame.size.width -= kMargin * 2
    frame.origin.y += 9 // TODO: configurable
    frame.size.height -= 9  // TODO: configurable
    return frame
  }
  
  func layoutNotifications() {
    // TODO: handle a relayout -- relaying out this view right now adds duplicate notificationViews
    if superview == nil {
      return
    }
    
    var notificationViewFrame = notificationViewFrameInView(superview!)
    
    for (i, notification) in notifications.enumerated() {
      notificationViewFrame.origin.x = CGFloat(i) * notificationViewFrame.size.width
      
      var notificationView = delegate?.bulletinViewNotificationViewForNotification(notification)
      if notificationView == nil {
        notificationView = HermesDefaultNotificationView()
        (notificationView as! HermesDefaultNotificationView).style = style
      }
      notificationView!.frame = notificationViewFrame
      notificationView!.notification = notification
      
      if notification.action != nil {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(HermesBulletinView.action(_:)))
        notificationView?.addGestureRecognizer(tapGesture)
      }
      
      scrollView.addSubview(notificationView!)
    }
    
    scrollView.contentSize = CGSize(width: notificationViewFrame.maxX, height: scrollView.bounds.size.height)
  }
  
  func action(_ tapGesture: UITapGestureRecognizer) {
    let notificationView = tapGesture.view as! HermesNotificationView
    if let notification = notificationView.notification {
      notification.invokeAction()
    }
  }
  
  override func layoutSubviews() {
    backgroundView?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: superview!.bounds.size.height)
    
    scrollView.frame = bounds
    
    let tabViewFrame = CGRect(x: 0, y: 9, width: 32, height: 5)
    tabView.frame = tabViewFrame
    tabView.center = CGPoint(x: bounds.size.width / 2, y: tabView.center.y)
    
    layoutNotifications()
  }
  
  func pageFromOffset(_ offset: CGPoint) -> Int {
    let boundsWidth = scrollView.bounds.size.width
    let pageWidth = boundsWidth
    return Int((offset.x + pageWidth * 0.5) / pageWidth)
  }
  
  // MARK: - Overrides
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    var rect = bounds
    rect.origin.y -= 44
    rect.size.height += 44
    return rect.contains(point)
  }
  
  // MARK: - UIScrollViewDelegate
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    timer?.invalidate()
    currentPage = pageFromOffset(scrollView.contentOffset)
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let currentPage = self.currentPage
    let targetOffset = targetContentOffset.pointee
    let targetPage = pageFromOffset(targetOffset)
    
    var newPage = currentPage
    if targetPage > currentPage {
      newPage += 1
    } else if targetPage < currentPage {
      newPage -= 1
    }
    
    targetContentOffset.initialize(to: self.contentOffsetForPage(newPage))
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scheduleCloseTimer()
  }
  
  // MARK: - HermesNotificationDelegate
  func notificationDidChangeAutoClose(_ notification: HermesNotification) {
    if notification == currentNotification {
      if notification.autoClose {
        scheduleCloseTimer()
      } else {
        timer?.invalidate()
      }
    }
  }
}
