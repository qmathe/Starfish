/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

public struct Subscription<T>: Hashable {

	public typealias EventHandler = (Flux<T>.Event<T>) -> ()
	public typealias ValueHandler = (T) -> ()
	public typealias ErrorHandler = (Error) -> ()
	public typealias Completion = () -> ()

	public enum Action {
	case event(EventHandler)
	case value(ValueHandler, ErrorHandler, Completion)
	// NOTE: We could support ErrorSelector, CompletionSelector and EventSelector too. 
	case valueSelector(receiver: AnyObject?, sender: AnyObject?, selector: Selector)
	}

	public let id = UUID()
	public unowned let flux: Flux<T>
	public let subscriber: AnyObject?
	public let action: Action
	public var hashValue: Int {
		return id.hashValue
	}
	
	init(flux: Flux<T>, subscriber: AnyObject?, valueHandler: @escaping ValueHandler, errorHandler: @escaping ErrorHandler, completion: @escaping Completion) {
		self.flux = flux
		self.subscriber = subscriber
		self.action = Action.value(valueHandler, errorHandler, completion)
	}

	init(flux: Flux<T>, subscriber: AnyObject?, eventHandler: @escaping EventHandler) {
		self.flux = flux
		self.subscriber = subscriber
		self.action = Action.event(eventHandler)
	}
}


public func == <T, U>(lhs: Subscription<T>, rhs: Subscription<U>) -> Bool {
    return lhs.id == rhs.id
}
