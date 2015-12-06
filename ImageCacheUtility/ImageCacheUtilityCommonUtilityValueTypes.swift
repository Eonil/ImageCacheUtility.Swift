//
//  ImageCacheUtilityCommonUtilityValueTypes.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public enum ResultWithTimeConstraint<T> {
	/// Couldn't produce result due to out of time.
	case OutOfTime
	/// Searching is done for all dataset in time, and result is
	/// accurate.
	case InTime(T?)
}
public func == <T: Equatable>(a: ResultWithTimeConstraint<T>, b: ResultWithTimeConstraint<T>) -> Bool {
	switch (a, b) {
	case (.OutOfTime, .OutOfTime):			return true
	case (.OutOfTime, .InTime):			return false
	case (.InTime, .OutOfTime):			return false
	case (.InTime(let a1), .InTime(let b1)):	return a1 == b1
	}
}

public extension TimeInterval {
	func measureExcutionTime(@noescape f: ()->()) -> TimeInterval {
		let startPoint = Timepoint.now()
		f()
		let endpoint = Timepoint.now()
		let duration = endpoint - startPoint
		return duration
	}
}

/// Measured in kernel absolute time. (seems to be a CPU clock time.
public struct Timepoint: Hashable {
	private init(seconds: CFTimeInterval) {
		self.seconds = seconds
	}
	public static func now() -> Timepoint {
		return Timepoint(seconds: CACurrentMediaTime())
	}
	public var hashValue: Int {
		get {
			return seconds.hashValue
		}
	}
	private let seconds: CFTimeInterval
}

/// A time interval in nanoseconds.
public struct TimeInterval {
	public init(seconds: CFTimeInterval) {
		self.seconds = seconds
	}
	private let seconds: CFTimeInterval
}
public func == (a: Timepoint, b: Timepoint) -> Bool {
	return a.seconds == b.seconds
}
public func < (a: Timepoint, b: Timepoint) -> Bool {
	return a.seconds < b.seconds
}
public func - (a: Timepoint, b: Timepoint) -> TimeInterval {
	return TimeInterval(seconds: a.seconds - b.seconds)
}
public func + (a: TimeInterval, b: TimeInterval) -> TimeInterval {
	return TimeInterval(seconds: a.seconds + b.seconds)
}
public func == (a: TimeInterval, b: TimeInterval) -> Bool {
	return a.seconds == b.seconds
}
public func < (a: TimeInterval, b: TimeInterval) -> Bool {
	return a.seconds < b.seconds
}


