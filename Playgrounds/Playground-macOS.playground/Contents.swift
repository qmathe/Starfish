//: Playground - noun: a place where people can play

import Cocoa
import Starfish

func section(_ title: String, closure: () -> ()) {
	print("\n\(title)\n")
	closure()
}


let flux = Flux<Int>()
let wave = Wave<Int>()

flux.subscribe { event in
    print("Received flux event \(event)")
}

flux.append(Flux<Int>.Event.value(5))

wave.subscribe { event in
    print("Received wave event \(event)")
}

wave.append(Wave<Int>.Event.value(flux))

section("Map Example") {
	Flux<Int>([1, 2, 3]).map { $0 * $0 }.subscribe { print($0) }
}