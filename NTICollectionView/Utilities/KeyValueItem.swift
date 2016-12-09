//
//  KeyValueItem.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 3/8/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public typealias KeyValueTransformer = (AnyObject?) -> String?
public typealias KeyValueImageTransformer = (AnyObject?) -> UIImage?

public enum KeyValueItemType: Int {
	case `default`, button, url
}

/// Content items for the `KeyValueDataSource` and `TextValueDataSource` data sources.
///
/// `KeyValueItem` instances have a title and a value. The value may be a string, a button, or a URL and is obtained via a key path on the source object of the `KeyValueDataSource`. A transformer may be set to modify the string or button value. In addition, for buttons, a transformer is available to provide an image for the button.
open class KeyValueItem: NSObject {

	public init(localizedTitle: String, keyPath: String? = nil, transformer: KeyValueTransformer? = nil) {
		self.localizedTitle = localizedTitle
		self.keyPath = keyPath
		self.transformer = transformer
	}
	
	open class func buttonItemWithLocalizedTitle(_ title: String, keyPath: String, transformer: @escaping KeyValueTransformer, imageTransformer: @escaping KeyValueImageTransformer, action: Selector) -> KeyValueItem {
		let item = KeyValueItem(localizedTitle: title, keyPath: keyPath, transformer: transformer)
		item.imageTransformer = imageTransformer
		item.action = action
		item.itemType = .button
		return item
	}
	
	open class func URLWithLocalizedTitle(_ title: String, keyPath: String, transformer: KeyValueTransformer? = nil) -> KeyValueItem {
		let item = KeyValueItem(localizedTitle: title, keyPath: keyPath, transformer: transformer)
		item.itemType = .url
		return item
	}
	
	/// What kind of item is this?
	open fileprivate(set) var itemType: KeyValueItemType = .default
	
	/// The title to display for `self`.
	open var localizedTitle: String
	
	/// The key path associated with `self`.
	open var keyPath: String?
	
	/// The transformer for the value of `self` when representing a string or a button.
	open var transformer: KeyValueTransformer?
	
	/// The transformer for the image of `self` when representing a button.
	open var imageTransformer: KeyValueImageTransformer?
	
	/// For button items, this is the action that will be sent up the responder chain when the button is tapped.
	open var action: Selector?
	
	/// Return a string value based on the provided object. 
	/// 
	/// This uses the transformer property if one is assigned.
	open func valueForObject(_ object: AnyObject) -> String? {
		var value: AnyObject?
		if let keyPath = self.keyPath {
			value = object.value(forKeyPath: keyPath)
		}
		else {
			value = object
		}
		
		if let transformer = self.transformer {
			value = transformer(value) as AnyObject?
		}
		
		if !(value is String) {
			if let number = value as? NSNumber {
				value = number.stringValue as AnyObject?
			} else {
				value = value?.description as AnyObject?
			}
		}
		
		return value as? String
	}
	
	/// Return an image value based on the provided object. 
	/// 
	/// This method requires imageTransformer be non-nil.
	/// - note: This is a synchronous operation. The image must already be available.
	open func imageForObject(_ object: AnyObject) -> UIImage? {
		var value: AnyObject?
		if let keyPath = self.keyPath {
			value = object.value(forKeyPath: keyPath)
		}
		
		if imageTransformer == nil || value is String {
			return nil
		}
		
		return imageTransformer?(value)
	}
	
}
