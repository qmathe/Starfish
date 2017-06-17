/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation
import Dispatch

extension Flux {

	func forward<V>(on stream: Flux<V>, with transform: @escaping (T) throws -> V) -> Flux<V> {
		return propagate(on: stream) { event, stream in
			switch event {
			case .value(let value):
				// TODO: Catch transform error and wrap it into an event to forward
				if let newValue = try? transform(value) {
					stream.append(Flux<V>.Event<V>.value(newValue))
				}
			case .error(let error):
				stream.append(Flux<V>.Event<V>.error(error))
			case .completed:
				stream.append(Flux<V>.Event<V>.completed)
			}
		}
	}
	
	func propagate<V>(on stream: Flux<V>, with reaction: @escaping (Event<T>, Flux<V>) -> ()) -> Flux<V> {
		_ = subscribe(stream) { event in
			reaction(event, stream)
		}
		return stream
	}

	open func map<V>(_ transform: @escaping (T) throws -> V) rethrows -> Flux<V> {
		return forward(on: Flux<V>(), with: transform)
	}

    open func flatMap<V>(_ transform: @escaping (T) throws -> Flux<V>) rethrows -> Flux<Flux<V>> {
        return forward(on: Flux<Flux<V>>(), with: transform)
    }
	
	open func filter(_ isIncluded: @escaping (T) throws -> Bool) rethrows -> Flux<T> {
		return propagate(on: Flux()) { event, stream in
			switch event {
			case .value(let value):
				if (try? isIncluded(value)) ?? false {
					stream.append(event)
				}
			default:
				stream.append(event)
			}
		}
	}
	
	open func start(with initialValues: [T]) -> Flux<T> {
		let initialEvents = initialValues.map { Event<T>.value($0) }
		events.insert(contentsOf: initialEvents, at: 0)
		send()
		return forward(on: Flux()) { $0 }
	}
	
	open func delay(_ seconds: TimeInterval) -> Flux<T> {
		return propagate(on: Flux()) { event, stream in
			switch event {
			case .error(_):
				stream.append(event)
			default:
				stream.queue.asyncAfter(deadline: .now() + seconds) {
					stream.append(event)
				}
			}
		}
	}

	// NOTE: An alternative name could be switch(to queue).
	open func run(in queue: DispatchQueue) -> Flux<T> {
		return forward(on: Flux(queue: queue)) { $0 }
	}
}
