//
//  GridSupplementaryAttributes.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/18/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

// MARK: - GridSupplementaryAttributeProvider

public protocol GridSupplementaryAttributeProvider {
	
	/// Use top & bottom layoutMargin to adjust spacing of header & footer elements. Not all headers & footers adhere to layoutMargins. Default is UIEdgeInsetsZero which is interpreted by supplementary items to be their default values.
	var layoutMargins: UIEdgeInsets { get set }
	
	/// The background color that should be used for this supplementary view. If not set, this will be inherited from the section.
	var backgroundColor: UIColor? { get set }
	
	/// The background color shown when this header is selected. If not set, this will be inherited from the section. This will only be used when simulatesSelection is YES.
	var selectedBackgroundColor: UIColor? { get set }
	
	/// The color to use for the background when the supplementary view has been pinned. If not set, this will be inherited from the section's backgroundColor value.
	var pinnedBackgroundColor: UIColor? { get set }
	
	/// Should the header/footer show a separator line? When shown, the separator will be shown using the separator color.
	var showsSeparator: Bool { get set }
	
	/// The color to use when showing the bottom separator line (if shown). If not set, this will be inherited from the section.
	var separatorColor: UIColor? { get set }
	
	/// The color to use when showing the bottom separator line if the supplementary view has been pinned. If not set, this will be inherited from the section's separatorColor value.
	var pinnedSeparatorColor: UIColor? { get set }
	
	/// Should this supplementary view simulate selection highlighting like cells?
	var simulatesSelection: Bool { get set }
	
}
