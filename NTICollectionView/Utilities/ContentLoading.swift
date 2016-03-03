//
//  ContentLoading.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

public enum LoadState: String {
	case Initial, LoadingContent, RefreshingContent
	case LoadingNextContent, LoadingPreviousContent
	case ContentLoaded, NoContent, Error
}

public protocol ContentLoading: NSObjectProtocol {
	
	/// The current state of the content loading operation.
	var loadingState: LoadState { get }
	
	/// Any error that occurred during content loading.
	var loadingError: NSError? { get }
	
	/// Used to begin loading the content.
	func loadContent(with progress: LoadingProgress)
	
	/// Used to reset the content of the receiver.
	func resetContent()
	
}

/// A block that performs updates on the object that is loading. The object parameter is the receiver of the `-loadContentWithProgress:` message.
public typealias LoadingUpdateBlock = AnyObject -> Void

/// A protocol that defines content loading behavior.
public protocol LoadingProgress: NSObjectProtocol {
	
	var isCancelled: Bool { get }
	
	/// Signals that this result should be ignored.
	func ignore()
	
	/// Signals that loading is complete with no errors.
	func done()
	
	/// Signals that loading failed with an error.
	func done(with error: NSError)
	
	/// Signals that loading is complete.
	func updateWithContent(update: LoadingUpdateBlock)
	
	/// Signals that loading completed with no content.
	func updateWithNoContent(update: LoadingUpdateBlock)
	
}

public typealias LoadingProgressCompletionHandler = (state: LoadState?, error: NSError?, update: LoadingUpdateBlock?) -> Void

public class BasicLoadingProgress: NSObject, LoadingProgress {
	
	public init(completionHandler: LoadingProgressCompletionHandler) {
		self.completionHandler = completionHandler
		super.init()
	}
	
	public private(set) var isCancelled = false
	
	private var completionHandler: LoadingProgressCompletionHandler!
	
	/// Sends a nil value for the state to the completion handler.
	public func ignore() {
		done(state: nil, error: nil, update: nil)
	}
	
	/// This triggers a transition to the Loaded state.
	public func done() {
		done(state: .ContentLoaded, error: nil, update: nil)
	}
	
	/// This triggers a transition to the Error state.
	public func done(with error: NSError) {
		done(state: .Error, error: error, update: nil)
	}
	
	/// Transitions into the Loaded state and then runs the update block.
	public func updateWithContent(update: LoadingUpdateBlock) {
		done(state: .ContentLoaded, error: nil, update: update)
	}
	
	/// Transitions to the No Content state and then runs the update block.
	public func updateWithNoContent(update: LoadingUpdateBlock) {
		done(state: .NoContent, error: nil, update: update)
	}
	
	private func done(state newState: LoadState?, error: NSError?, update: LoadingUpdateBlock?) {
		guard let handler = completionHandler else {
			return
		}
		dispatch_async(dispatch_get_main_queue()) {
			handler(state: newState, error: error, update: update)
		}
		completionHandler = nil
	}
	
}
