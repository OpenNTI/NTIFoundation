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
private var onceToken: dispatch_once_t = 0

public class PlaceholderView: UIView {
	
	public init(frame: CGRect, title: String?, message: String?, image: UIImage?, buttonTitle: String? = nil, buttonAction: dispatch_block_t? = nil) {
		self.title = title
		self.message = message
		self.image = image
		self.buttonTitle = buttonTitle
		self.buttonAction = buttonAction
		super.init(frame: frame)
		configure()
	}
	
	public var title: String? {
		didSet {
			guard title != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	public var message: String? {
		didSet {
			guard message != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	public var image: UIImage? {
		didSet {
			guard image != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	public var buttonTitle: String? {
		didSet {
			guard buttonTitle != oldValue else {
				return
			}
			updateViewHierarchy()
		}
	}
	
	public var buttonAction: dispatch_block_t?
	
	public var titleFont = UIFont.systemFontOfSize(14) {
		didSet { titleLabel.font = titleFont }
	}
	
	public var messageFont = UIFont.systemFontOfSize(14) {
		didSet { messageLabel.font = messageFont }
	}
	
	public var textColor = UIColor(white: textColorWhiteValue, alpha: 1) {
		didSet {
			titleLabel.textColor = textColor
			messageLabel.textColor = textColor
		}
	}
	
	private var containerView = UIView(frame: CGRectZero)
	private var imageView: UIImageView!
	private var titleLabel = UILabel(frame: CGRectZero)
	private var messageLabel = UILabel(frame: CGRectZero)
	private var actionButton = UIButton(type: .System)
	private var _constraints: [NSLayoutConstraint] = []
	private var topConstraint: NSLayoutConstraint!
	
	private func configure() {
		autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		containerView.translatesAutoresizingMaskIntoConstraints = false
		
		configureImageView()
		configureTitleLabel()
		configureMessageLabel()
		configureActionButton()
		
		addSubview(containerView)
		
		updateViewHierarchy()
		
		activateContainerConstraints()
	}
	
	private func configureImageView() {
		imageView = UIImageView(image: image)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(imageView)
	}
	
	private func configureTitleLabel() {
		titleLabel.textAlignment = .Center
		titleLabel.backgroundColor = nil
		titleLabel.opaque = false
		titleLabel.font = UIFont.systemFontOfSize(14)
		titleLabel.numberOfLines = 0
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = textColor
		containerView.addSubview(titleLabel)
	}
	
	private func configureMessageLabel() {
		messageLabel.textAlignment = .Center
		messageLabel.opaque = false
		messageLabel.backgroundColor = nil
		messageLabel.font = UIFont.systemFontOfSize(14)
		messageLabel.numberOfLines = 0
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.textColor = textColor
		containerView.addSubview(messageLabel)
	}
	
	private func configureActionButton() {
		actionButton.addTarget(self, action: #selector(PlaceholderView.actionButtonPressed(_:)), forControlEvents: .TouchUpInside)
		actionButton.frame = CGRect(x: 0, y: 0, width: 124, height: 29)
		actionButton.titleLabel?.font = UIFont.systemFontOfSize(14)
		actionButton.translatesAutoresizingMaskIntoConstraints = false
		actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		actionButton.setBackgroundImage(backgroundImage(with: textColor), forState: .Normal)
		actionButton.setTitleColor(textColor, forState: .Normal)
		containerView.addSubview(actionButton)
	}
	
	private func backgroundImage(with color: UIColor) -> UIImage {
		dispatch_once(&onceToken) {
			var cornerRadius = defaultCornerRadius
			
			let capSize = ceil(cornerRadius * continuousCurvesSizeFactor)
			let rectSize = 2 * capSize + 1
			let rect = CGRect(x: 0, y: 0, width: rectSize, height: rectSize)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
			
			// Pull in the stroke a wee bit
			let pathRect = CGRectInset(rect, 0.5, 0.5)
			cornerRadius -= 0.5
			let path = UIBezierPath(roundedRect: pathRect, cornerRadius: cornerRadius)
			
			color.set()
			path.stroke()
			
			cachedBackgroundImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			cachedBackgroundImage = cachedBackgroundImage.resizableImageWithCapInsets(UIEdgeInsets(uniformInset: capSize))
		}
		
		return cachedBackgroundImage
	}
	
	private func updateViewHierarchy() {
		if image != nil {
			containerView.addSubview(imageView)
			imageView.image = image
		} else {
			imageView.removeFromSuperview()
		}
		
		if let title = self.title where !title.characters.isEmpty {
			containerView.addSubview(titleLabel)
			titleLabel.text = title
		} else {
			titleLabel.removeFromSuperview()
		}
		
		if let message = self.message where !message.characters.isEmpty {
			containerView.addSubview(messageLabel)
			messageLabel.text = message
		} else {
			messageLabel.removeFromSuperview()
		}
		
		if let buttonTitle = self.buttonTitle where !buttonTitle.characters.isEmpty {
			containerView.addSubview(actionButton)
			actionButton.setTitle(buttonTitle, forState: .Normal)
		} else {
			actionButton.removeFromSuperview()
		}
		
		if !_constraints.isEmpty {
			NSLayoutConstraint.deactivateConstraints(_constraints)
		}
		
		_constraints.removeAll(keepCapacity: true)
		setNeedsUpdateConstraints()
	}
	
	private func activateContainerConstraints() {
		var constraints: [NSLayoutConstraint] = []
		
		constraints.append(NSLayoutConstraint(item: containerView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
		
		topConstraint = NSLayoutConstraint(item: containerView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
		constraints.append(topConstraint)
		
		let views = ["containerView": containerView]
		let metrics = ["i": 30.0]
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[containerView]-(>=i)-|", options: [], metrics: metrics, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=i)-[containerView]-(>=i)-|", options: [], metrics: metrics, views: views)
		
		NSLayoutConstraint.activateConstraints(constraints)
	}

	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	public func actionButtonPressed(sender: AnyObject) {
		buttonAction?()
	}
	
	public override func layoutSubviews() {
		topConstraint.constant = ceil(bounds.height * 0.5)
		super.layoutSubviews()
	}
	
	public override func updateConstraints() {
		defer {
			super.updateConstraints()
		}
		guard _constraints.isEmpty else {
			return
		}
		
		var constraints: [NSLayoutConstraint] = []
		
		let views = ["imageView": imageView, "titleLabel": titleLabel, "messageLabel": messageLabel, "actionButton": actionButton]
		var last = containerView
		var lastAttr: NSLayoutAttribute = .Top
		var constant: CGFloat = 0
		
		func constraintPinningViewToLast(view: UIView) -> NSLayoutConstraint {
			return NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: last, attribute: lastAttr, multiplier: 1, constant: constant)
		}
		
		if imageView.superview != nil {
			constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=0)-[imageView]-(>=0)-|", options: [], metrics: nil, views: views)
			constraints.append(NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: last, attribute: .CenterX, multiplier: 1, constant: 0))
			constraints.append(constraintPinningViewToLast(imageView))
			
			last = imageView
			lastAttr = .Bottom
			constant = 30
		}
		
		if titleLabel.superview != nil {
			constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: [], metrics: nil, views: views)
			constraints.append(constraintPinningViewToLast(titleLabel))
			
			last = titleLabel
			lastAttr = .Baseline
			constant = 20
		}
		
		if messageLabel.superview != nil {
			constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[messageLabel]|", options: [], metrics: nil, views: views)
			constraints.append(constraintPinningViewToLast(messageLabel))
			
			last = messageLabel
			lastAttr = .Baseline
			constant = 20
		}
		
		if actionButton.superview != nil {
			constraints.append(constraintPinningViewToLast(actionButton))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .CenterX, relatedBy: .Equal, toItem: containerView, attribute: .CenterX, multiplier: 1, constant: 0))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: buttonWidth))
			constraints.append(NSLayoutConstraint(item: actionButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: buttonHeight))
			last = actionButton
		}
		
		constraints.append(NSLayoutConstraint(item: last, attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: 1, constant: 0))
		NSLayoutConstraint.activateConstraints(constraints)
		_constraints += constraints
	}
	
}
