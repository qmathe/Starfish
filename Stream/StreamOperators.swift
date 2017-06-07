/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation
import Dispatch

extension Stream {

	open func map<V>(_ transform: @escaping (T) throws -> V) rethrows -> Stream<V> {
		let stream = Stream<V>()
		
		_ = subscribe(stream) { event in
			switch event {
			case .value(let value):
				if let mappedValue = try? transform(value) {
					stream.append(Stream<V>.Event<V>.value(mappedValue))
				}
			case .error(let error):
				stream.append(Stream<V>.Event<V>.error(error))
			case .completed:
				stream.append(Stream<V>.Event<V>.completed)
			}
		}
		return stream
	}

    open func flatMap<V>(_ transform: @escaping (T) throws -> Stream<V>) rethrows -> Stream<Stream<V>> {
        let stream = Stream<Stream<V>>()
        
        _ = subscribe(stream) { event in
            switch event {
            case .value(let value):
                if let mappedValue = try? transform(value) {
                    stream.append(Stream<Stream<V>>.Event<Stream<V>>.value(mappedValue))
                }
            case .error(let error):
                stream.append(Stream<Stream<V>>.Event<Stream<V>>.error(error))
            case .completed:
                stream.append(Stream<Stream<V>>.Event<Stream<V>>.completed)
            }
        }
        return stream
    }
	
	open func filter(_ isIncluded: @escaping (T) throws -> Bool) rethrows -> Stream<T> {
		let stream = Stream()
		
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
	
	open func delay(_ seconds: TimeInterval) -> Stream<T> {
		let stream = Stream()

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
	open func run(in queue: DispatchQueue) -> Stream<T> {
		let stream = Stream(queue: queue)
		
		_ = subscribe(stream) { event in
			stream.append(event)
		}
		return stream
	}
}
