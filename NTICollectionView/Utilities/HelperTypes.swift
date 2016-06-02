//
//  HelperTypes.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

public enum Result<T> {
	
	case success(T)
	
	case failure(NSError)
	
}
