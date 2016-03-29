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
	case Default, Button, URL
}

/// Content items for the `KeyValueDataSource` and `TextValueDataSource` data sources.
///
/// `KeyValueItem` instances have a title and a value. The value may be a string, a button, or a URL and is obtained via a key path on the source object of the `KeyValueDataSource`. A transformer may be set to modify the string or button value. In addition, for buttons, a transformer is available to provide an image for the button.
public class KeyValueItem: NSObject {

	public init(localizedTitle: String, keyPath: String? = nil, transformer: KeyValueTransformer? = nil) {
		self.localizedTitle = localizedTitle
		self.keyPath = keyPath
		self.transformer = transformer
	}
	
	public class func buttonItemWithLocalizedTitle(title: String, keyPath: String, transformer: KeyValueTransformer, imageTransformer: KeyValueImageTransformer, action: Selector) -> KeyValueItem {
		let item = KeyValueItem(localizedTitle: title, keyPath: keyPath, transformer: transformer)
		item.imageTransformer = imageTransformer
		item.action = action
		item.itemType = .Button
		return item
	}
	
	public class func URLWithLocalizedTitle(title: String, keyPath: String, transformer: KeyValueTransformer? = nil) -> KeyValueItem {
		let item = KeyValueItem(localizedTitle: title, keyPath: keyPath, transformer: transformer)
		item.itemType = .URL
		return item
	}
	
	/// What kind of item is this?
	public private(set) var itemType: KeyValueItemType = .Default
	
	/// The title to display for `self`.
	public var localizedTitle: String
	
	/// The key path associated with `self`.
	public var keyPath: String?
	
	/// The transformer for the value of `self` when representing a string or a button.
	public var transformer: KeyValueTransformer?
	
	/// The transformer for the image of `self` when representing a button.
	public var imageTransformer: KeyValueImageTransformer?
	
	/// For button items, this is the action that will be sent up the responder chain when the button is tapped.
	public var action: Selector?
	
	/// Return a string value based on the provided object. 
	/// 
	/// This uses the transformer property if one is assigned.
	public func valueForObject(object: AnyObject) -> String? {
		var value: AnyObject?
		if let keyPath = self.keyPath {
			value = object.valueForKeyPath(keyPath)
		}
		else {
			value = object
		}
		
		if let transformer = self.transformer {
			value = transformer(value)
		}
		
		if !(value is String) {
			if let number = value as? NSNumber {
				value = number.stringValue
			} else {
				value = value?.description
			}
		}
		
		return value as? String
	}
	
	/// Return an image value based on the provided object. 
	/// 
	/// This method requires imageTransformer be non-nil.
	/// - note: This is a synchronous operation. The image must already be available.
	public func imageForObject(object: AnyObject) -> UIImage? {
		var value: AnyObject?
		if let keyPath = self.keyPath {
			value = object.valueForKeyPath(keyPath)
		}
		
		if imageTransformer == nil || value is String {
			return nil
		}
		
		return imageTransformer?(value)
	}
	
}
