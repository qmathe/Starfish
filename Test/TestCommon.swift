/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import XCTest
@testable import Starfish

extension XCTestCase {

	func wait(_ delay: TimeInterval = 0.001) {
		RunLoop.main.run(until: Date(timeIntervalSinceNow: delay))
	}
}

typealias Event<T> = Flux<T>.Event<T>

func XCTAssertEqual(_ expression1: @autoclosure () throws -> [Event<Int>], _ expression2: @autoclosure () throws -> [Event<Int>], _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
	guard let lhs = try? expression1(), let rhs = try? expression2() else {
		XCTFail()
		return
	}

	if equalEvents(lhs, rhs) {
		XCTAssertTrue(true)
	} else {
		print("Expected \(lhs), got \(rhs)")
		XCTFail()
	}
}

// TODO: With Swift 4, we could support extension Event: Equatable where T: Equatable { }
private func equalEvents(_ lhs: [Event<Int>], _ rhs: [Event<Int>]) -> Bool {
	guard lhs.count == rhs.count else {
		return false
	}
	for (index, element) in lhs.enumerated() {
		if !(element == rhs[index]) {
			return false
		}
	}
	return true
}

func == (lhs: Event<Int>, rhs: Event<Int>) -> Bool {
	switch (lhs, rhs) {
	case (Event<Int>.value(let value1), Event<Int>.value(let value2)):
		return value1 == value2
	case (Event<Int>.error(_), Event<Int>.error(_)):
		return true
	case (Event<Int>.completed, Event<Int>.completed):
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
