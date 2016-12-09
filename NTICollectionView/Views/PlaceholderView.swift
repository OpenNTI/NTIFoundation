//
//  PlaceholderView.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/25/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

let defaultCornerRadius: CGFloat = 3
let verticalElementSpacing: CGFloat = 35
let continuousCurvesSizeFactor: CGFloat = 1.528665
let buttonWidth: CGFloat = 124
let buttonHeight: CGFloat = 19
let textColorWhiteValue: CGFloat = 172.0 / 0xFF

private var cachedBackgroundImage: UIImage!
private var onceToken: Int = 0

open class PlaceholderView: UIView {
	
	private static var __once: () = {
			var cornerRadius = defaultCornerRadius
			
			let capSize = ceil(cornerRadius * continuousCurvesSizeFactor)
			let rectSize = 2 * capSize + 1
			let rect = CGRect(x: 0, y: 0, width: rectSize, height: rectSize)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
			
			// Pull in the stroke a wee bit
			let pathRect = rect.insetBy(dx: 0.5, dy: 0.5)
			cornerRadius -= 0.5
			let path = UIBezierPath(roundedRect: pathRect, cornerRadius: cornerRadius)
			
			color.set()
			path.stroke()
			
			cachedBackgroundImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			cachedBackgroundImage = cachedBackgroundImage.resizableImage(withCapInsets: UIEdgeInsets(uniformInset: capSize))
		}()
	
	public init(frame: CGRect, title: String?, message: String?, image: UIImage?, buttonTitle: String? = nil, buttonAction: @escaping ()->()? = nil) {
		self.title = title
		self.message = message
		self.image = image
		self.buttonTitle = buttonTitle
		self.buttonAction = buttonAction
		super.init(frame: frame)
		configure()
	}
	
	open var title: String? {
		didSet {
			guard title != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	open var message: String? {
		didSet {
			guard message != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	open var image: UIImage? {
		didSet {
			guard image != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	open var buttonTitle: String? {
		didSet {
			guard buttonTitle != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	open var buttonAction: ()->()?
	
	open var titleFont = UIFont.systemFont(ofSize: 14) {
		didSet { titleLabel.font = titleFont }
	}
	
	open var messageFont = UIFont.systemFont(ofSize: 14) {
		didSet { messageLabel.font = messageFont }
	}
	
	open var textColor = UIColor(white: textColorWhiteValue, alpha: 1) {
		didSet {
			titleLabel.textColor = textColor
			messageLabel.textColor = textColor
		}
	}
	
	fileprivate var containerView = UIView(frame: CGRect.zero)
	fileprivate var imageView: UIImageView!
	fileprivate var titleLabel = UILabel(frame: CGRect.zero)
	fileprivate var messageLabel = UILabel(frame: CGRect.zero)
	fileprivate var actionButton = UIButton(type: .system)
	fileprivate var _constraints: [NSLayoutConstraint] = []
	fileprivate var topConstraint: NSLayoutConstraint!
	
	fileprivate func configure() {
		autoresizingMask = [.flexibleWidth, .flexibleHeight]
		containerView.translatesAutoresizingMaskIntoConstraints = false
		
		configureImageView()
		configureTitleLabel()
		configureMessageLabel()
		configureActionButton()
		
		addSubview(containerView)
		
		updateViewHierarchy()
		
		activateContainerConstraints()
	}
	
	fileprivate func configureImageView() {
		imageView = UIImageView(image: image)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(imageView)
	}
	
	fileprivate func configureTitleLabel() {
		titleLabel.textAlignment = .center
		titleLabel.backgroundColor = nil
		titleLabel.isOpaque = false
		titleLabel.font = UIFont.systemFont(ofSize: 14)
		titleLabel.numberOfLines = 0
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = textColor
		containerView.addSubview(titleLabel)
	}
	
	fileprivate func configureMessageLabel() {
		messageLabel.textAlignment = .center
		messageLabel.isOpaque = false
		messageLabel.backgroundColor = nil
		messageLabel.font = UIFont.systemFont(ofSize: 14)
		messageLabel.numberOfLines = 0
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.textColor = textColor
		containerView.addSubview(messageLabel)
	}
	
	fileprivate func configureActionButton() {
		actionButton.addTarget(self, action: #selector(PlaceholderView.actionButtonPressed(_:)), for: .touchUpInside)
		actionButton.frame = CGRect(x: 0, y: 0, width: 124, height: 29)
		actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
		actionButton.translatesAutoresizingMaskIntoConstraints = false
		actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		actionButton.setBackgroundImage(backgroundImage(with: textColor), for: UIControlState())
		actionButton.setTitleColor(textColor, for: UIControlState())
		containerView.addSubview(actionButton)
	}
	
	fileprivate func backgroundImage(with color: UIColor) -> UIImage {
		_ = PlaceholderView.__once
		
		return cachedBackgroundImage
	}
	
	fileprivate func updateViewHierarchy() {
		if image != nil {
			containerView.addSubview(imageView)
			imageView.image = image
		} else {
			imageView.removeFromSuperview()
		}
		
		if let title = self.title, !title.characters.isEmpty {
			containerView.addSubview(titleLabel)
			titleLabel.text = title
		} else {
			titleLabel.removeFromSuperview()
		}
		
		if let message = self.message, !message.characters.isEmpty {
			containerView.addSubview(messageLabel)
			messageLabel.text = message
		} else {
			messageLabel.removeFromSuperview()
		}
		
		if let buttonTitle = self.buttonTitle, !buttonTitle.characters.isEmpty {
			containerView.addSubview(actionButton)
			actionButton.setTitle(buttonTitle, for: UIControlState())
		} else {
			actionButton.removeFromSuperview()
		}
		
		if !_constraints.isEmpty {
			NSLayoutConstraint.deactivate(_constraints)
		}
		
		_constraints.removeAll(keepingCapacity: true)
		setNeedsUpdateConstraints()
	}
	
	fileprivate func activateContainerConstraints() {
		var constraints: [NSLayoutConstraint] = []
		
		constraints.append(NSLayoutConstraint(item: containerView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
		
		topConstraint = NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
		constraints.append(topConstraint)
		
		let views = ["containerView": containerView]
		let metrics = ["i": 30.0]
		
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[containerView]-(>=i)-|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=i)-[containerView]-(>=i)-|", options: [], metrics: metrics, views: views)
		
		NSLayoutConstraint.activate(constraints)
	}

	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	open func actionButtonPressed(_ sender: AnyObject) {
		buttonAction()
	}
	
	open override func layoutSubviews() {
		topConstraint.constant = ceil(bounds.height * 0.5)
		super.layoutSubviews()
	}
	
	open override func updateConstraints() {
		defer {
			super.updateConstraints()
		}
		guard _constraints.isEmpty else {
			return
		}
		
		var constraints: [NSLayoutConstraint] = []
		
		let views = ["imageView": imageView, "titleLabel": titleLabel, "messageLabel": messageLabel, "actionButton": actionButton] as [String : Any]
		var last = containerView
		var lastAttr: NSLayoutAttribute = .top
		var constant: CGFloat = 0
		
		func constraintPinningViewToLast(_ view: UIView) -> NSLayoutConstraint {
			return NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: last, attribute: lastAttr, multiplier: 1, constant: constant)
		}
		
		if imageView.superview != nil {
			constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=0)-[imageView]-(>=0)-|", options: [], metrics: nil, views: views)
			constraints.append(NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: last, attribute: .centerX, multiplier: 1, constant: 0))
			constraints.append(constraintPinningViewToLast(imageView))
			
			last = imageView
			lastAttr = .bottom
			constant = 30
		}
		
		if titleLabel.superview != nil {
			constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleLabel]|", options: [], metrics: nil, views: views)
			constraints.append(constraintPinningViewToLast(titleLabel))
			
			last = titleLabel
			lastAttr = .lastBaseline
			constant = 20
		}
		
		if messageLabel.superview != nil {
			constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[messageLabel]|", options: [], metrics: nil, views: views)
			constraints.append(constraintPinningViewToLast(messageLabel))
			
			last = messageLabel
			lastAttr = .lastBaseline
			constant = 20
		}
		
		if actionButton.superview != nil {
			constraints.append(constraintPinningViewToLast(actionButton))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1, constant: 0))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonWidth))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: buttonHeight))
			last = actionButton
		}
		
		constraints.append(NSLayoutConstraint(item: last, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0))
		NSLayoutConstraint.activate(constraints)
		_constraints += constraints
	}
	
}
