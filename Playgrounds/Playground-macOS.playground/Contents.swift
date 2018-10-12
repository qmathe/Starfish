//: Playground - noun: a place where people can play

import Cocoa
import Starfish

func section(_ title: String, closure: () -> ()) {
	print("\n\(title)\n")
	closure()
}

max([5, 2].count, 3)

typealias Event<T> = Flux<T>.Event<T>

// TODO: With Swift 4, we could support extension Event: Equatable where T: Equatable { }
private func equalEvents <T>(_ lhs: [Event<T>], _ rhs: [Event<T>], _ equal: (T, T) -> Bool) -> Bool {
	guard lhs.count == rhs.count else {
		return false
	}
	for (index, lhsElement) in lhs.enumerated() {
		let rhsElement = rhs[index]
		if !equalEvent(lhsElement, rhsElement, equal) {
			return false
		}
	}
	return true
}

func equalEvent<T>(_ lhs: Event<T>, _ rhs: Event<T>, _ equal: (T, T) -> Bool) -> Bool {
	switch (lhs, rhs) {
	case (Event<T>.value(let value1), Event<T>.value(let value2)):
		return equal(value1, value2)
	case (Event<T>.error(_), Event<T>.error(_)):
		return true
	case (Event<T>.completed, Event<T>.completed):
		return true
	default:
		return false
	}
}

let flux1 = Flux<Int>([0, 2])
let flux2 = Flux<Int>([1, 3])
var receivedEvents = [Event<(Int, Int)>]()
let expectedEvents = Flux<(Int, Int)>.events([(0, 1), (2, 3), (2, 5)])

_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
wait()

flux2.appendValue(5)

print(expectedEvents)
print(receivedEvents)

equalEvents(expectedEvents, receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })

