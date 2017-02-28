//
//  StateMachine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

public enum StateMachineError: Error {
	case illegalTransition(fromState: String, toState: String)
}

open class StateMachine: NSObject {
	
	public init(initialState: String, validTransitions: [String: Set<String>]) {
		currentState = initialState
		self.validTransitions = validTransitions
		super.init()
	}
	
	open fileprivate(set) var currentState: String
	
	open var validTransitions: [String: Set<String>] = [:]
	
	open weak var delegate: StateMachineDelegate?
	
	open func canTransition(to newState: String) -> Bool {
		return validTransitions[currentState]?.contains(newState) ?? false
	}
	
	open func apply(_ state: String) throws {
		let fromState = currentState
		guard let appliedToState = try validateTransition(from: fromState, to: state) else {
			return
		}

		if let delegate = self.delegate {
			delegate.stateWillChange(to: appliedToState)
		}
		
		currentState = appliedToState
		performTransition(from: fromState, to: currentState)
	}
	
	fileprivate func validateTransition(from fromState: String, to toState: String) throws -> String? {
		guard let validTransitions = self.validTransitions[fromState] else {
			throw StateMachineError.illegalTransition(fromState: fromState, toState: toState)
		}
		var toState = toState
		
		let transitionSpecified = validTransitions.contains(toState)
		if !transitionSpecified {
			// Silently fail if implict transition to the same state
			if fromState == toState {
				return nil
			}
			guard let newState = try triggerMissingTransition(from: fromState, to: toState) else {
				return nil
			}
			toState = newState
		}
		
		if let delegate = self.delegate, !delegate.shouldEnter(toState) {
			guard let newState = try triggerMissingTransition(from: fromState, to: toState) else {
				return nil
			}
			toState = newState
		}
		
		return toState
	}
	
	fileprivate func triggerMissingTransition(from fromState: String, to toState: String) throws -> String? {
		guard let delegate = self.delegate else {
			throw StateMachineError.illegalTransition(fromState: fromState, toState: toState)
		}
		return try delegate.missingTransition(from: fromState, to: toState)
	}

	func performTransition(from fromState: String, to toState: String) {
		guard let delegate = self.delegate else {
			return
		}
		delegate.stateDidChange(to: toState, from: fromState)
	}
	
}

public protocol StateMachineDelegate: NSObjectProtocol {
	
	func missingTransition(from fromState: String, to toState: String) throws -> String?
	
	func stateWillChange(to newState: String)
	
	func stateDidChange(to newState: String, from oldState: String)
	
	func shouldEnter(_ state: String) -> Bool
	
}

extension StateMachineDelegate {
	
	public func missingTransition(from fromState: String, to toState: String) throws -> String? {
		throw StateMachineError.illegalTransition(fromState: fromState, toState: toState)
	}
	
	public func shouldEnter(_ state: String) -> Bool {
		return true
	}
	
}
