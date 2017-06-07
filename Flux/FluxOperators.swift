/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation
import Dispatch

extension Flux {

	open func map<V>(_ transform: @escaping (T) throws -> V) rethrows -> Flux<V> {
		let stream = Flux<V>()
		
		_ = subscribe(stream) { event in
			switch event {
			case .value(let value):
				if let mappedValue = try? transform(value) {
					stream.append(Flux<V>.Event<V>.value(mappedValue))
				}
			case .error(let error):
				stream.append(Flux<V>.Event<V>.error(error))
			case .completed:
				stream.append(Flux<V>.Event<V>.completed)
			}
		}
		return stream
	}

    open func flatMap<V>(_ transform: @escaping (T) throws -> Flux<V>) rethrows -> Flux<Flux<V>> {
        let stream = Flux<Flux<V>>()
        
        _ = subscribe(stream) { event in
            switch event {
            case .value(let value):
                if let mappedValue = try? transform(value) {
                    stream.append(Flux<Flux<V>>.Event<Flux<V>>.value(mappedValue))
                }
            case .error(let error):
                stream.append(Flux<Flux<V>>.Event<Flux<V>>.error(error))
            case .completed:
                stream.append(Flux<Flux<V>>.Event<Flux<V>>.completed)
            }
        }
        return stream
    }
	
	open func filter(_ isIncluded: @escaping (T) throws -> Bool) rethrows -> Flux<T> {
		let stream = Flux()
		
		_ = subscribe(stream) { event in
			switch event {
			case .value(let value):
				if (try? isIncluded(value)) ?? false {
					stream.append(event)
				}
			default:
				stream.append(event)
			}
		}
		return stream
	}
	
	open func delay(_ seconds: TimeInterval) -> Flux<T> {
		let stream = Flux()

		_ = subscribe(stream) { event in
			switch event {
			case .error(_):
				stream.append(event)
			default:
				stream.queue.asyncAfter(deadline: .now() + seconds) {
					stream.append(event)
				}
			}
		}
		return stream
	}

	// NOTE: An alternative name could be switch(to queue).
	open func run(in queue: DispatchQueue) -> Flux<T> {
		let stream = Flux(queue: queue)
		
		_ = subscribe(stream) { event in
			stream.append(event)
		}
		return stream
	}
}
