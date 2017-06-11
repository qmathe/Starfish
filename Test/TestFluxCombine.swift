/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import XCTest
@testable import Starfish

class TestFluxCombine: XCTestCase {

	func testWaveMergeOnCreate() {
		let flux1 = Flux<Int>([0, 2])
		let flux2 = Flux<Int>([1, 3])
		let wave = Wave<Int>([Event<Flux<Int>>.value(flux1), Event<Flux<Int>>.value(flux2)])
		var receivedEvents = [Event<Int>]()
		
		_ = wave.merge().subscribe { event in receivedEvents += [event] }
		wait()
		
		XCTAssertTrue(equalEvents([0, 2, 1, 3].map { Event<Int>.value($0) }, receivedEvents))
	}
	
	func testWaveMergeOnAppend() {
		let flux1 = Flux<Int>([0, 2])
		let flux2 = Flux<Int>([1, 3])
		let wave = Wave<Int>()
		var receivedEvents = [Event<Int>]()

		wave.appendValue(flux1)

		_ = wave.merge().subscribe { event in receivedEvents += [event] }
		wait()
		
		wave.appendValue(flux2)
		
		XCTAssertTrue(equalEvents([0, 2, 1, 3].map { Event<Int>.value($0) }, receivedEvents))
	}
	
	func testWaveMergeOnAppendToFlux() {
		let flux1 = Flux<Int>()
		let flux2 = Flux<Int>()
		let wave = Wave<Int>([Event<Flux<Int>>.value(flux1), Event<Flux<Int>>.value(flux2)])
		var receivedEvents = [Event<Int>]()

		flux1.appendValue(4)

		_ = wave.merge().subscribe { event in receivedEvents += [event] }
		wait()
		
		flux2.appendValue(5)
		
		XCTAssertTrue(equalEvents([4, 5].map { Event<Int>.value($0) }, receivedEvents))
	}

	func testSwitchLatest() {
		let flux1 = Flux<Int>([0, 2])
		let flux2 = Flux<Int>([1, 3])
		let wave = Wave<Int>()
		var receivedEvents = [Event<Int>]()
		
		wave.appendValue(flux1)
		
		_ = wave.switchLatest().subscribe { event in receivedEvents += [event] }
		wait()
		
		wave.appendValue(flux2)
		
		flux1.appendValue(4)
		flux2.appendValue(5)

		XCTAssertTrue(equalEvents([0, 2, 1, 3, 5].map { Event<Int>.value($0) }, receivedEvents))
	}
}
