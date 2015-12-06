//
//  RingBuffer.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

struct RingBuffer<T>: SequenceType {
	init(capacity: Int) {
		precondition(capacity > 0)
		slots.reserveCapacity(capacity)
		for _ in 0..<capacity {
			slots.append(nil)
		}
	}

	private(set) var count: Int = 0
	var capacity: Int {
		get {
			return slots.count
		}
	}

	var first: T? {
		get {
			guard count > 0 else { return nil }
			return slots[mapIndex(0)]
		}
	}
	var last: T? {
		get {
			guard count > 0 else { return nil }
			return slots[mapIndex(count - 1)]
		}
	}
	subscript(index: Int) -> T {
		get {
			precondition(index < count)
			return slots[mapIndex(index)]!
		}
		set {
			precondition(index < count)
			slots[mapIndex(index)] = newValue
		}
	}
	func generate() -> AnyGenerator<T> {
		func unwrappingGenerator(g: Slice<[T?]>.Generator) -> AnyGenerator<T> {
			var g1 = g
			return anyGenerator({ () -> T? in
				if let v = g1.next() {
					return v!
				}
				return nil
			})
		}
		guard count > 0 else {
			return anyGenerator({ nil })
		}
		guard fullStartIndex < emptyStartIndex else {
			let slice0 = Slice(base: slots, bounds: fullStartIndex..<slots.endIndex)
			let slice1 = Slice(base: slots, bounds: 0..<emptyStartIndex)
			let gen0 = unwrappingGenerator(slice0.generate())
			let gen1 = unwrappingGenerator(slice1.generate())
			var gen0Done = false
			return anyGenerator({ () -> T? in
				if gen0Done == false {
					if let v = gen0.next() {
						return v
					}
					gen0Done = true
				}
				return gen1.next()
			})
		}
		let slice0 = Slice(base: slots, bounds: fullStartIndex..<emptyStartIndex)
		return unwrappingGenerator(slice0.generate())
	}

	mutating func appendLast(value: T) {
		precondition(count < capacity)
		precondition(slots[emptyStartIndex] == nil)
		slots[emptyStartIndex] = value
		count += 1
		emptyStartIndex += 1
		if emptyStartIndex == capacity {
			emptyStartIndex = 0
		}
	}
	mutating func removeFirst() -> T {
		precondition(count > 0)
		precondition(slots[fullStartIndex] != nil)
		let value = slots[fullStartIndex]!
		slots[fullStartIndex] = nil
		fullStartIndex += 1
		count -= 1
		if fullStartIndex == capacity {
			fullStartIndex = 0
		}
		return value
	}

	// MARK: -
	private var slots: [T?] = []
	private var fullStartIndex: Int = 0
	private var emptyStartIndex: Int = 0
	private func mapIndex(index: Int) -> Int {
		let index1 = fullStartIndex + index
		if index1 >= capacity {
			let index2 = index1 - capacity
			return index2
		}
		return index1
	}
}










