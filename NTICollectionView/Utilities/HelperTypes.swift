//
//  HelperTypes.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public enum Result<T> {
	
	case success(T)
	
	case failure(NSError)
	
}

/// Conforming types can be initialized with a single `CGRect` parameter called `frame`.
public protocol FrameInitializable {
	
	init(frame: CGRect)
	
}
