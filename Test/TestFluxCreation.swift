/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import XCTest
@testable import Starfish

class TestFluxCreation: XCTestCase {

	func testNever() {
		let flux = Flux<Int>()
		var called = false
		
		_ = flux.subscribe { _ in called = true }
		wait()
		
		XCTAssertFalse(called)
	}
	
	func testEmpty() {
		let sentEvents = [Event<Int>.completed]
		let flux = Flux<Int>(sentEvents)
		var receivedEvents = [Event<Int>]()
		
		_ = flux.subscribe { event in receivedEvents += [event] }
		wait()
		
		XCTAssertTrue(equalEvents(sentEvents, receivedEvents))
	}
}
