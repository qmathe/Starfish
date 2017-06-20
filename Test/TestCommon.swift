/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import XCTest
@testable import Starfish

struct DummyError: Error {

}

extension XCTestCase {

	func wait(_ delay: TimeInterval = 0.001) {
		RunLoop.main.run(until: Date(timeIntervalSinceNow: delay))
	}
}

typealias Event<T> = Flux<T>.Event<T>

func XCTAssertEqual<T: Equatable>(_ expression1: @autoclosure () throws -> [Event<T>], _ expression2: @autoclosure () throws -> [Event<T>], _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
	XCTAssertEqual(expression1, expression2, { $0 == $1 }, message, file: file, line: line)
}

// Arrays and tuples (tuples nested in arrarys in our test case) doesn't conform to Equatable and cannot be 
// extended to do so in Swift 3:
//
// - we implement equalEvents() to compare event arrays
// - we pass a closure to decide whether two event values are equal or not rather instead of using ==
func XCTAssertEqual<T>(_ expression1: @autoclosure () throws -> [Event<T>], _ expression2: @autoclosure () throws -> [Event<T>], _ equal: (T, T) -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
	guard let lhs = try? expression1(), let rhs = try? expression2() else {
		XCTFail()
		return
	}

	if equalEvents(lhs, rhs, equal) {
		XCTAssertTrue(true)
	} else {
		print("Expected \(lhs), got \(rhs)")
		XCTFail()
	}
}

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

func == <T: Equatable>(lhs: Event<T>, rhs: Event<T>) -> Bool {
	switch (lhs, rhs) {
	case (Event<T>.value(let value1), Event<T>.value(let value2)):
		return value1 == value2
	case (Event<T>.error(_), Event<T>.error(_)):
		return true
	case (Event<T>.completed, Event<T>.completed):
		return true
	default:
		return false
	}
}

extension Event {

	var value: T? {
		guard case .value(let value) = self else {
			return nil
		}
		return value
	}
}
