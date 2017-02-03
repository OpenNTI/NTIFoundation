//
//  TruncatingLabel.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/14/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit
import CoreText

/// A `UILabel` that draws an additional string when the text is truncated.
open class TruncatingLabel: UILabel {

	/// The text to display when truncated.
	///
	/// This is displayed to the right of the text.
	/// Default is "more".
	/// The truncationText is displayed in the tintColor of this view.
	/// This property can be reset to the default by setting it to `nil`.
	open var truncationText: String! {
		get {
			return _truncationText
		}
		set {
			guard truncationText != newValue else {
				return
			}
			
			_truncationText = newValue
			
			if _truncationText == nil {
				resetTruncationText()
			}
			
			setNeedsDisplay()
		}
	}
	
	fileprivate var _truncationText: String?
	
	fileprivate func resetTruncationText() {
		_truncationText = NSLocalizedString("more", comment: "Default text to display after truncated text.")
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	
	public convenience init() {
		self.init(frame: CGRect.zero)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}
	
	fileprivate func commonInit() {
		resetTruncationText()
	}
	
	fileprivate var framesetter: CTFramesetter? {
		if let framesetter = _framesetter {
			return framesetter
		}
		
		guard let attributedText = self.attributedText else {
			return nil
		}
		
		_framesetter = CTFramesetterCreateWithAttributedString(attributedText)
		return _framesetter
	}
	
	fileprivate func setNeedsFramesetter() {
		_framesetter = nil
	}
	
	fileprivate var _framesetter: CTFramesetter?
	
	open override var text: String? {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override var attributedText: NSAttributedString? {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override var font: UIFont! {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override var textColor: UIColor! {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override var textAlignment: NSTextAlignment {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override var lineBreakMode: NSLineBreakMode {
		willSet {
			setNeedsFramesetter()
		}
	}
	
	open override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
		var bounds = bounds
		bounds.size = makeSizeFitting(bounds.size, attributedString: attributedText, numberOfLines: numberOfLines)
		return bounds
	}
	
	fileprivate func makeSizeFitting(_ size: CGSize, attributedString: NSAttributedString?, numberOfLines: Int) -> CGSize {
		guard let attributedString = attributedString,
			let framesetter = self.framesetter else {
				return CGSize.zero
		}
		
		var rangeToSize = CFRange(location: 0, length: attributedString.length)
		let constraints = CGSize(width: size.width, height: .greatestFiniteMagnitude)
		
		if numberOfLines > 0 {
			// If the line count of the label is more than 1, limit `rangeToSize` to the number of lines that have been set
			let path = CGMutablePath()
			CGPathAddRect(path, nil, CGRect(origin: CGPoint.zero, size: constraints))
			let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
			
			let lines = CTFrameGetLines(frame)
			let lineCount = CFArrayGetCount(lines)
			
			if lineCount > 0 {
				let lastVisibleLineIndex = min(numberOfLines, lineCount - 1)
				let lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex) as! CTLine
				
				let rangeToLayout = CTLineGetStringRange(lastVisibleLine)
				rangeToSize = CFRange(location: 0, length: rangeToLayout.location + rangeToLayout.length)
			}
		}
		
		let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, nil, constraints, nil)
		
		return CGSize(width: ceil(suggestedSize.width), height: ceil(suggestedSize.height))
	}
	
	open override func drawText(in rect: CGRect) {
		guard !rect.isEmpty, let textAttributedString = self.attributedText else {
			return
		}
		
		guard let context = UIGraphicsGetCurrentContext() else {
			return
		}
		
		let textAttributes: [String: Any] = [
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: textColor
		]
		let truncationAttributes: [String : Any] = [
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: tintColor
		]
		
		var ellipsisString: NSAttributedString?
		var moreString: NSAttributedString?
		
		if numberOfLines > 0 {
			let ellipsis = NSLocalizedString("…", comment: "Ellipsis used for truncation.")
			ellipsisString = NSAttributedString(string: ellipsis, attributes: textAttributes)
			
			let truncationString = NSMutableAttributedString(attributedString: ellipsisString!)
			truncationString.append(NSAttributedString(string: " ", attributes: textAttributes))
			truncationString.append(NSAttributedString(string: truncationText, attributes: truncationAttributes))
			moreString = truncationString
		}
		
		draw(textAttributedString, ellipsisString: ellipsisString, moreString: moreString, rect: rect, context: context)
	}
	
	fileprivate func draw(_ attributedString: NSAttributedString, ellipsisString: NSAttributedString?, moreString: NSAttributedString?, rect frameRect: CGRect, context: CGContext) {
		guard let framesetter = self.framesetter else {
			return
		}
		
		context.saveGState()
		defer { context.restoreGState() }
		
		// Flip the coordinate system
		context.textMatrix = CGAffineTransform.identity
		context.translateBy(x: 0, y: bounds.size.height)
		context.scaleBy(x: 1, y: -1)
		
		let fontRef = CGFont(font.fontName)
		context.setFont(fontRef!)
		context.setFontSize(font.pointSize)
		
		// Create a path in which to render text
		// Don't set any line break modes, etc, just let the frame draw as many full lines as will fit
		let framePath = CGMutablePath()
		CGPathAddRect(framePath, nil, frameRect)
		let fullStringRange = CFRange(location: 0, length: CFAttributedStringGetLength(attributedString))
		let frameRef = CTFramesetterCreateFrame(framesetter, fullStringRange, framePath, nil)
		
		let lines = CTFrameGetLines(frameRef)
		let numberOfLines = CFArrayGetCount(lines)
		var origins: [CGPoint] = .init(repeating: CGPoint.zero, count: numberOfLines)
		CTFrameGetLineOrigins(frameRef, CFRange(location: 0, length: numberOfLines), &origins)
		
		let shouldTruncate = ellipsisString != nil && moreString != nil
		
		let numberOfUntruncatedLines = shouldTruncate ? numberOfLines - 1 : numberOfLines
		
		for lineIndex in 0..<numberOfUntruncatedLines {
			// Draw each line in the correct position as-is
			let x = origins[lineIndex].x + frameRect.origin.x
			let y = origins[lineIndex].y + frameRect.origin.y
			CGContextSetTextPosition(context, x, y)
			let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)
			CTLineDraw(line, context)
		}
		
		guard let ellipsisString = ellipsisString, let moreString = moreString else {
			return
		}
		
		// Truncate the last line before drawing it
		if numberOfLines > 0 && shouldTruncate {
			let lastOrigin = origins[numberOfLines - 1]
			let lastLine = unsafeBitCast(CFArrayGetValueAtIndex(lines, numberOfLines - 1), to: CTLine.self)
			
			// The truncation token is a CTLineRef itself; use the ellipsis for single line and the more string for multiline
			let truncationToken = CTLineCreateWithAttributedString(numberOfLines > 1 ? moreString : ellipsisString)
			var truncated: CTLine!
			
			// Now create the truncated line -- need to grab extra characters from the source string,  or else the system will see the line as already fitting within the given width and will not truncate it
			let lastLineRange = CTLineGetStringRange(lastLine)
			if lastLineRange.length == 1 && Array(attributedString.string.characters)[lastLineRange.location] == "\n" {
				truncated = truncationToken
			}
			else {
				// Range to cover everything from the start of lastLine to the end of the string
				var range = NSRange(location: lastLineRange.location, length: 0)
				range.length = attributedString.length - range.location
				
				// Substring with that range
				let longString = NSMutableAttributedString(attributedString: attributedString.attributedSubstring(from: range))
				// FIXME: Need to reset the text color for the final line, it seems to get lost for some reason
				longString.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location: 0, length: longString.length))
				
				// Line for that string
				let longLine = CTLineCreateWithAttributedString(longString)
				
				truncated = CTLineCreateTruncatedLine(longLine, Double(frameRect.size.width), .end, truncationToken)
				
				// If the truncation call fails, we'll use the last line
				if truncated == nil {
					truncated = lastLine
				}
			}
			
			// Draw it at the same offset as the non-truncated version
			CGContextSetTextPosition(context, lastOrigin.x + frameRect.origin.x, lastOrigin.y + frameRect.origin.y)
			CTLineDraw(truncated, context)
		}
	}

}
