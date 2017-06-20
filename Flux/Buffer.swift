/**
	Copyright (C) 2017 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2017
	License:  MIT
 */

import Foundation

protocol Buffer {

}

class EmptyBuffer: Buffer {

}

class FlatBuffer2<T, V>: Buffer {
	var value1: T?
	var value2: V?
}

class Buffer2<T, V>: Buffer {
	var values1: [T] = []
	var values2: [V] = []
}
