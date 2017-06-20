/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

open class Flux<T>: MutableCollection, RangeReplaceableCollection {

	public enum Event<T> {
		case value(T)
		case error(Error)
		case completed
	}
	
	public enum State {
		case active
		case paused
		case failed(Error)
		case completed
	}

	open internal(set) var events = [Event<T>]()
	var buffer: Buffer = EmptyBuffer()
	public internal(set) var state = State.active
	open private(set) var subscriptions = Set<Subscription<T>>()
	open private(set) var paused = false
	public let queue: DispatchQueue
	
	public class func events(_ values: [T]) -> [Event<T>] {
		return values.map { Event<T>.value($0) }
	}

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
	
	public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Iterator.Element == Flux.Iterator.Element  {
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
	
	/// Initalizes a new stream from another event sequence.
	///
	/// Operators and subscription callbacks will be executed in the main queue.
	///
	/// Can be used as RX Just and From operators.
	public required init<S>(_ elements: S) where S : Sequence, S.Iterator.Element == Flux.Iterator.Element {
		events = Array(elements)
		queue = DispatchQueue.main
	}
	
	public convenience init<S>(_ elements: S) where S : Sequence, S.Iterator.Element == T {
		self.init(elements.map { Event<T>.value($0) })
	}
	
	public required init(_ stream: Flux<T>, queue: DispatchQueue = DispatchQueue.main) {
		self.events = stream.events
		self.subscriptions = stream.subscriptions
		self.queue = queue
	}

	public required init(interval: TimeInterval, repeats: Bool, queue: DispatchQueue) {
		self.queue = queue
	}
	
	// MARK: - Subcribing to Events
	
	open func subscribe(_ subscriber: AnyObject? = nil, sendNow: Bool = true, valueHandler: @escaping Subscription<T>.ValueHandler, errorHandler: @escaping Subscription<T>.ErrorHandler = { _ in }, completion: @escaping Subscription<T>.Completion = {}) -> Subscription<T> {
		let subscription = Subscription(flux: self, subscriber: subscriber, valueHandler: valueHandler, errorHandler: errorHandler, completion: completion)
		subscriptions.insert(subscription)
		send(sendNow ? Int.max : 0)
		return subscription
	}

	open func subscribe(_ subscriber: AnyObject? = nil, sendNow: Bool = true, eventHandler: @escaping Subscription<T>.EventHandler) -> Subscription<T> {
		let subscription = Subscription(flux: self, subscriber: subscriber, eventHandler: eventHandler)
		subscriptions.insert(subscription)
		send(sendNow ? Int.max : 0)
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
	
	open func appendValue(_ value: T) {
		append(Event<T>.value(value))
	}
	
	// MARK: - Sending Events
	
	open func send(_ count: Int = Int.max) {
		guard case .active = state, !subscriptions.isEmpty else {
			return
		}
		for event in events.prefix(count) {
			for subscription in subscriptions {
				dispatch(event, with: subscription)
			}
			switch event {
			case .error(let error):
				state = .failed(error)
				break
			case .completed:
				state = .completed
				break
			default:
				()
			}
		}
		events.removeFirst(count == Int.max ? events.count : count)
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
		guard case .active = state else {
			return
		}
		state = .paused
	}
	
	open func resume() {
		guard case .paused = state else {
			return
		}
		state = .active
		send()
	}
}

