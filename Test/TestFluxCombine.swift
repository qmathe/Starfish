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
	
	func testCombineLatest() {
		let flux1 = Flux<Int>([0, 2])
		let flux2 = Flux<Int>([1, 3])
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux2.appendValue(5)

		XCTAssertEqual(Flux<(Int, Int)>.events([(0, 1), (2, 1), (2, 3), (2, 5)]), receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
	}
	
	func testCombineLatestOnFirstFluxError() {
		let flux1 = Flux<Int>([0])
		let flux2 = Flux<Int>([1])
		let sentEvents = [Event<(Int, Int)>.value((0, 1)), Event<(Int, Int)>.error(DummyError())]
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux1.append(Event<Int>.error(DummyError()))
		flux1.appendValue(4)
		flux2.appendValue(5)

		XCTAssertEqual(sentEvents, receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
	}
	
	func testCombineLatestOnSecondFluxError() {
		let flux1 = Flux<Int>([0])
		let flux2 = Flux<Int>([1])
		let sentEvents = [Event<(Int, Int)>.value((0, 1)), Event<(Int, Int)>.error(DummyError())]
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux2.append(Event<Int>.error(DummyError()))
		flux1.appendValue(4)
		flux2.appendValue(5)

		XCTAssertEqual(sentEvents, receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
	}
	
	func testCombineLatestOnFirstFluxCompleted() {
		let flux1 = Flux<Int>([0])
		let flux2 = Flux<Int>([1])
		let sentEvents = [Event<(Int, Int)>.value((0, 1)), Event<(Int, Int)>.completed]
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux1.append(Event<Int>.completed)
		flux1.appendValue(4)
		flux2.appendValue(5)

		XCTAssertEqual(sentEvents, receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
	}
	
	func testCombineLatestOnSecondFluxCompleted() {
		let flux1 = Flux<Int>([0])
		let flux2 = Flux<Int>([1])
		let sentEvents = [Event<(Int, Int)>.value((0, 1)), Event<(Int, Int)>.completed]
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.combineLatest(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux2.append(Event<Int>.completed)
		flux1.appendValue(4)
		flux2.appendValue(5)

		XCTAssertEqual(sentEvents, receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
	}
	
	func testZip() {
		let flux1 = Flux<Int>([0, 2])
		let flux2 = Flux<Int>([1, 3])
		var receivedEvents = [Event<(Int, Int)>]()
		
		_ = flux1.zip(with: flux2).subscribe { event in receivedEvents += [event] }
		wait()

		flux2.appendValue(5)
		flux2.appendValue(7)
		flux1.appendValue(8)

		XCTAssertEqual(Flux<(Int, Int)>.events([(0, 1), (2, 3), (8, 5)]), receivedEvents, { $0.0 == $1.0 && $0.1 == $1.1 })
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
