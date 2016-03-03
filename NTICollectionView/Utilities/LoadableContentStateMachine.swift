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
public class LoadableContentStateMachine: NSObject, StateMachineDelegate {
	
	public static let initialState: LoadState = .Initial
	
	private class var stringInitialState: String {
		return initialState.rawValue
	}
	
	public static let validTransitions: [LoadState: Set<LoadState>] = [
		.Initial: [.LoadingContent],
		.LoadingContent: [.ContentLoaded, .NoContent, .Error],
		.RefreshingContent: [.ContentLoaded, .NoContent, .Error],
		.ContentLoaded: [.RefreshingContent, .NoContent, .Error, .LoadingNextContent, .LoadingPreviousContent],
		.LoadingNextContent: [.ContentLoaded],
		.LoadingPreviousContent: [.ContentLoaded],
		.NoContent: [.RefreshingContent, .ContentLoaded, .Error],
		.Error: [.LoadingContent, .RefreshingContent, .NoContent, .ContentLoaded]
	]
	
	private class var stringValidTransitions: [String: Set<String>] {
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
	
	private var stateMachine: StateMachine
	
	public weak var delegate: LoadableContentStateMachineDelegate? {
		didSet {
			stateMachine.delegate = (delegate != nil) ? self : nil
		}
	}
	
	public var currentState: LoadState {
		return LoadState(rawValue: stateMachine.currentState)!
	}
	
	public func apply(state: LoadState) throws {
		try stateMachine.apply(state.rawValue)
	}
	
	public func canTransition(to newState: LoadState) -> Bool {
		return stateMachine.canTransition(to: newState.rawValue)
	}
	
	public func missingTransition(from fromState: String, to toState: String) throws -> String? {
		let fromState = LoadState(rawValue: fromState)!
		let toState = LoadState(rawValue: toState)!
		return delegate?.missingTransition(from: fromState, to: toState)?.rawValue
	}
	
	public func stateWillChange(to newState: String) {
		let newState = LoadState(rawValue: newState)!
		delegate?.stateWillChange(to: newState)
	}
	
	public func stateDidChange(to newState: String, from oldState: String) {
		let newState = LoadState(rawValue: newState)!
		let oldState = LoadState(rawValue: oldState)!
		delegate?.stateDidChange(to: newState, from: oldState)
	}
	
	public func shouldEnter(state: String) -> Bool {
		let state = LoadState(rawValue: state)!
		return delegate?.shouldEnter(state) ?? true
	}
	
}

public protocol LoadableContentStateMachineDelegate: NSObjectProtocol {
	
	func missingTransition(from fromState: LoadState, to toState: LoadState) -> LoadState?
	
	func stateWillChange(to newState: LoadState)
	
	func stateDidChange(to newState: LoadState, from oldState: LoadState)
	
	func shouldEnter(state: LoadState) -> Bool
	
}

extension LoadableContentStateMachineDelegate {
	
	public func missingTransition(from fromState: LoadState, to toState: LoadState) -> LoadState? {
		return nil
	}
	
	public func shouldEnter(state: LoadState) -> Bool {
		return true
	}
	
}
