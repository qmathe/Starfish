/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import XCTest
@testable import Starfish

class TestFluxTransform: XCTestCase {

	func testMap() {
		let flux = Flux<Int>([0, 2, 4])
		var receivedEvents = [Event<Int>]()
		
		_ = flux.map { $0 * 2 }.subscribe { event in receivedEvents += [event] }
		wait()
		
		XCTAssertTrue(equalEvents(Flux<Int>.events([0, 4, 8]), receivedEvents))
	}
}
