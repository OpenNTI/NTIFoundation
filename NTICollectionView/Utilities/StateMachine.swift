//
//  StateMachine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

public enum StateMachineError: ErrorType {
	case IllegalTransition(fromState: String, toState: String)
}

public class StateMachine: NSObject {
	
	public init(initialState: String, validTransitions: [String: Set<String>]) {
		currentState = initialState
		self.validTransitions = validTransitions
		super.init()
	}
	
	public private(set) var currentState: String
	
	public var validTransitions: [String: Set<String>] = [:]
	
	public weak var delegate: StateMachineDelegate?
	
	public func canTransition(to newState: String) -> Bool {
		return validTransitions[currentState]?.contains(newState) ?? false
	}
	
	public func apply(state: String) throws {
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
	
	private func validateTransition(from fromState: String, to toState: String) throws -> String? {
		guard let validTransitions = self.validTransitions[fromState] else {
			throw StateMachineError.IllegalTransition(fromState: fromState, toState: toState)
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
		
		if let delegate = self.delegate where !delegate.shouldEnter(toState) {
			guard let newState = try triggerMissingTransition(from: fromState, to: toState) else {
				return nil
			}
			toState = newState
		}
		
		return toState
	}
	
	private func triggerMissingTransition(from fromState: String, to toState: String) throws -> String? {
		guard let delegate = self.delegate else {
			throw StateMachineError.IllegalTransition(fromState: fromState, toState: toState)
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
	
	func shouldEnter(state: String) -> Bool
	
}

extension StateMachineDelegate {
	
	public func missingTransition(from fromState: String, to toState: String) throws -> String? {
		throw StateMachineError.IllegalTransition(fromState: fromState, toState: toState)
	}
	
	public func shouldEnter(state: String) -> Bool {
		return true
	}
	
}