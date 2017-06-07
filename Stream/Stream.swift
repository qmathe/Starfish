/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

open class Stream<T>: MutableCollection, RangeReplaceableCollection {

	public enum Event<T> {
		case value(T)
		case error(Error)
		case completed
	}

	open private(set) var events = [Event<T>]()
	open private(set) var subscriptions = Set<Subscription<T>>()
	open private(set) var paused = false
	public let queue: DispatchQueue

	// MARK: - Collection Protocol

	public typealias Index = Int
	public var startIndex: Int { return events.startIndex }
	public var endIndex: Int { return events.endIndex }

    open subscript(i: Int) -> Event<T> {
		get {
			return events[i]
		}
		set {
			events[i] = newValue
		}
    }
	
	public func index(after i: Int) -> Int {
		return events.index(after: i)
	}
	
	public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Stream.Iterator.Element  {
		events.replaceSubrange(subrange, with: newElements)
	}
	
	// MARK: - Initialization
	
	
	/// Initializes a new empty stream.
	///
	/// Operators and subscription callbacks will be executed in the main queue.
	///
	/// Can be used as RX Empty operator.
	public required init() {
		queue = DispatchQueue.main
	}

	/// Initializes a new empty stream using a custom queue to execute operators
	/// and subscription callbacks.
	public required init(queue: DispatchQueue) {
		self.queue = queue
	}
	
	/// Initalizes a new stream from another sequence.
	///
	/// Operators and subscription callbacks will be executed in the main queue.
	///
	/// Can be used as RX Just and From operators.
	public required init<S>(_ elements: S) where S : Sequence, S.Iterator.Element == Stream.Iterator.Element {
		events = Array(elements)
		queue = DispatchQueue.main
	}
	
	public required init(_ stream: Stream, queue: DispatchQueue = DispatchQueue.main) {
		self.events = stream.events
		self.subscriptions = stream.subscriptions
		self.queue = queue
	}

	public required init(interval: TimeInterval, repeats: Bool, queue: DispatchQueue) {
		self.queue = queue
	}
	
	// MARK: - Subcribing to Events
	
	open func subscribe(_ subscriber: AnyObject? = nil, valueHandler: @escaping Subscription<T>.ValueHandler, errorHandler: @escaping Subscription<T>.ErrorHandler = { _ in }, completion: @escaping Subscription<T>.Completion = {}) -> Subscription<T> {
		let subscription = Subscription(subscriber: subscriber, valueHandler: valueHandler, errorHandler: errorHandler, completion: completion)
		subscriptions.insert(subscription)
		return subscription
	}

	open func subscribe(_ subscriber: AnyObject? = nil, eventHandler: @escaping Subscription<T>.EventHandler) -> Subscription<T> {
		let subscription = Subscription(subscriber: subscriber, eventHandler: eventHandler)
		subscriptions.insert(subscription)
		return subscription
	}

	open func unsubscribe(_ subscription: Subscription<T>) {
		subscriptions = Set(subscriptions.filter { $0 != subscription })
	}
	
	open func unsubscribe(_ subscriber: AnyObject) {
		subscriptions = Set(subscriptions.filter {
			guard let existingSubscriber = $0.subscriber else {
				return true
			}
			return ObjectIdentifier(existingSubscriber) != ObjectIdentifier(subscriber)
		})
	}
	
	// MARK: - Posting Events
	
	open func append(_ newElement: Event<T>) {
		events.append(newElement)
		send()
	}
	
	open func append<S>(contentsOf newElements: S) where S : Sequence, S.Iterator.Element == Event<T> {
		events.append(contentsOf: newElements)
		send()
	}
	
	// MARK: - Sending Events
	
	open func send() {
		if paused {
			return
		}
		for event in events {
			for subscription in subscriptions {
				dispatch(event, with: subscription)
			}
		}
		events.removeAll()
	}
	
	private func dispatch(_ event: Event<T>, with subscription: Subscription<T>) {
		switch subscription.action {
		case .event(let eventHandler):
			eventHandler(event)
		case .value(let valueHandler, let errorHandler, let completion):
			switch event {
			case .value(let value):
				valueHandler(value)
			case .error(let error):
				errorHandler(error)
			case .completed:
				completion()
			}
		case .valueSelector(receiver: _, sender: _, selector: _):
			fatalError("Unsupported value selector dispatch case")
		}
	}
	
	// MARK: - Controlling Sent Events
	
	open func pause() {
		paused = true
	}
	
	open func resume() {
		paused = false
		send()
	}
}

