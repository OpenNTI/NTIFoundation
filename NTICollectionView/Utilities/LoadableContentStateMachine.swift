//
//  LoadableContentStateMachine.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/22/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation

/**
A wrapper for `StateMachine` which exposes its API in terms of `LoadState` states instead of `String` states.
*/
open class LoadableContentStateMachine: NSObject, StateMachineDelegate {
	
	open static let initialState: LoadState = .Initial
	
	fileprivate class var stringInitialState: String {
		return initialState.rawValue
	}
	
	open static let validTransitions: [LoadState: Set<LoadState>] = [
		.Initial: [.LoadingContent],
		.LoadingContent: [.ContentLoaded, .NoContent, .Error],
		.RefreshingContent: [.ContentLoaded, .NoContent, .Error],
		.ContentLoaded: [.RefreshingContent, .NoContent, .Error, .LoadingNextContent, .LoadingPreviousContent],
		.LoadingNextContent: [.ContentLoaded],
		.LoadingPreviousContent: [.ContentLoaded],
		.NoContent: [.RefreshingContent, .ContentLoaded, .Error],
		.Error: [.LoadingContent, .RefreshingContent, .NoContent, .ContentLoaded]
	]
	
	fileprivate class var stringValidTransitions: [String: Set<String>] {
		var transitions: [String: Set<String>] = [:]
		for (fromState, toStates) in validTransitions {
			let fromString = fromState.rawValue
			let toStrings = Set(toStates.map { $0.rawValue })
			transitions[fromString] = toStrings
		}
		return transitions
	}
	
	public override init() {
		let initialState = LoadableContentStateMachine.stringInitialState
		let transitions = LoadableContentStateMachine.stringValidTransitions
		stateMachine = StateMachine(initialState: initialState, validTransitions: transitions)
		super.init()
	}
	
	fileprivate var stateMachine: StateMachine
	
	open weak var delegate: LoadableContentStateMachineDelegate? {
		didSet {
			stateMachine.delegate = (delegate != nil) ? self : nil
		}
	}
	
	open var currentState: LoadState {
		return LoadState(rawValue: stateMachine.currentState)!
	}
	
	open func apply(_ state: LoadState) throws {
		try stateMachine.apply(state.rawValue)
	}
	
	open func canTransition(to newState: LoadState) -> Bool {
		return stateMachine.canTransition(to: newState.rawValue)
	}
	
	open func missingTransition(from fromState: String, to toState: String) throws -> String? {
		let fromState = LoadState(rawValue: fromState)!
		let toState = LoadState(rawValue: toState)!
		return delegate?.missingTransition(from: fromState, to: toState)?.rawValue
	}
	
	open func stateWillChange(to newState: String) {
		let newState = LoadState(rawValue: newState)!
		delegate?.stateWillChange(to: newState)
	}
	
	open func stateDidChange(to newState: String, from oldState: String) {
		let newState = LoadState(rawValue: newState)!
		let oldState = LoadState(rawValue: oldState)!
		delegate?.stateDidChange(to: newState, from: oldState)
	}
	
	open func shouldEnter(_ state: String) -> Bool {
		let state = LoadState(rawValue: state)!
		return delegate?.shouldEnter(state) ?? true
	}
	
}

public protocol LoadableContentStateMachineDelegate: NSObjectProtocol {
	
	func missingTransition(from fromState: LoadState, to toState: LoadState) -> LoadState?
	
	func stateWillChange(to newState: LoadState)
	
	func stateDidChange(to newState: LoadState, from oldState: LoadState)
	
	func shouldEnter(_ state: LoadState) -> Bool
	
}

extension LoadableContentStateMachineDelegate {
	
	public func missingTransition(from fromState: LoadState, to toState: LoadState) -> LoadState? {
		return nil
	}
	
	public func shouldEnter(_ state: LoadState) -> Bool {
		return true
	}
	
}
