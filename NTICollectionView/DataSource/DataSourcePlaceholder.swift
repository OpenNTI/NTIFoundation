//
//  DataSourcePlaceholder.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/23/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol DataSourcePlaceholder: NSObjectProtocol {
	
	/// The title of the placeholder. This is typically displayed larger than the message.
	var title: String? { get set }
	
	/// The message of the placeholder. This is typically displayed using a smaller body font.
	var message: String? { get set }
	
	/// An image for the placeholder. This is displayed above the title.
	var image: UIImage? { get set }
	
}

public class BasicDataSourcePlaceholder: NSObject, DataSourcePlaceholder {
	
	public class func placeholderWithActivityIndicator() -> BasicDataSourcePlaceholder {
		let placeholder = BasicDataSourcePlaceholder()
		placeholder.isActivityIndicator = true
		return placeholder
	}
	
	public init(title: String? = nil, message: String? = nil, image: UIImage? = nil) {
		self.title = title
		self.message = message
		self.image = image
		super.init()
	}
	
	/// The title of the placeholder. This is typically displayed larger than the message.
	public var title: String?
	
	/// The message of the placeholder. This is typically displayed using a smaller body font.
	public var message: String?
	
	/// An image for the placeholder. This is displayed above the title.
	public var image: UIImage?
	
	/// Is this placeholder an activity indicator?
	public private(set) var isActivityIndicator: Bool = false
	
}
