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
		let wave = Wave<Int>(Wave<Int>.events([flux1, flux2]))
		var receivedEvents = [Event<Int>]()
		
		_ = wave.merge().subscribe { event in receivedEvents += [event] }
		wait()
		
		XCTAssertEqual(Flux<Int>.events([0, 2, 1, 3]), receivedEvents)
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
		
		XCTAssertEqual(Flux<Int>.events([0, 2, 1, 3]), receivedEvents)
	}
	
	func testWaveMergeOnAppendToFlux() {
		let flux1 = Flux<Int>()
		let flux2 = Flux<Int>()
		let wave = Wave<Int>(Wave<Int>.events([flux1, flux2]))
		var receivedEvents = [Event<Int>]()

		flux1.appendValue(4)

		_ = wave.merge().subscribe { event in receivedEvents += [event] }
		wait()
		
		flux2.appendValue(5)
		
		XCTAssertEqual(Flux<Int>.events([4, 5]), receivedEvents)
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

		XCTAssertEqual(Flux<Int>.events([0, 2, 1, 3, 5]), receivedEvents)
	}
}