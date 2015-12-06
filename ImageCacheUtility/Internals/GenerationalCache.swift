//
//  GenerationalCache.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

public struct GenerationalCacheConfiguration {
	public var segmentSize: Int
	public var maxSegmentCount: Int
	public var maxTotalCount: Int

	public init(segmentSize: Int, maxSegmentCount: Int, maxTotalCount: Int) {
		self.segmentSize = segmentSize
		self.maxSegmentCount = maxSegmentCount
		self.maxTotalCount = maxTotalCount
	}
	static func one() -> GenerationalCacheConfiguration {
		return GenerationalCacheConfiguration(segmentSize: 1, maxSegmentCount: 1, maxTotalCount: 1)
	}
}

/// Removes old entries automatically if dataset becomes too big.
/// You can't remove an entry manually.
///
/// This purges itself on system memory pressre event.
///
class GenerationalCache<K: Hashable,V>: Purgeable {
	/// - Parameter killSegment:
	///	Cleans up a segment AFTER it removed from this cache.
	///	This is useful if you're storing objects that need long time to clean-up. (`deinit`)
	///	In that case, you provide a function to do it in non-main thread.
	///	At point of calling this function, the segment is already been detached from this cache.
	init(configuration: GenerationalCacheConfiguration, killSegment: [K:V]->() = { _ in }) {
		precondition(configuration.maxTotalCount > 0)
		precondition(configuration.maxSegmentCount > 0)
		precondition(configuration.segmentSize > 0)
		self.configuration = configuration
		self.killSegment = killSegment
		self.segments = RingBuffer(capacity: configuration.maxSegmentCount)
		registerWeakReferenceToPurgeable(self)
	}
	deinit {
		deregisterWeakReferenceToPurgeable(self)
	}

	// MARK: -
	let configuration: GenerationalCacheConfiguration
	private(set) var totalCount: Int = 0
	func quickValueSearchForKey(key: K, timeConstraint: TimeInterval) -> ResultWithTimeConstraint<V> {
		return quickValueSearchForKeyImpl(key, timeConstraint: timeConstraint)
	}
	func setValue(value: V, forKey key: K) {
		addItem(key, value: value)
	}
	/// This does not try to keep any time constraint.
	/// Use only when required.
	func performEmergencyPurge() {
		performEmergencyPurgeImpl()
	}

	// MARK: -
	private typealias Segment = [K:V]
	private var segments: RingBuffer<Segment> // Older is at lower index.
	private let killSegment: [K:V]->()
	private func quickValueSearchForKeyImpl(key: K, timeConstraint: TimeInterval) -> ResultWithTimeConstraint<V> {
		let now = Timepoint.now()
		for segment in segments.reverse() {
			if let result = segment[key] {
				return ResultWithTimeConstraint.InTime(result)
			}
			let now1 = Timepoint.now()
			let delta = now1 - now
			guard delta < timeConstraint else {
				return ResultWithTimeConstraint.OutOfTime
			}
			continue
		}
		return ResultWithTimeConstraint.OutOfTime
	}
	private func addItem(key: K, value: V) {
		removeSegmentOnceIfNeeded()
		prepareSegmentForAdding()
		totalCount += 1
		segments[segments.count - 1][key] = value
	}
	private func removeSegmentOnceIfNeeded() {
		if totalCount == configuration.maxTotalCount {
			totalCount -= segments.count
			killSegment(segments.removeFirst())
		}
	}
	private func performEmergencyPurgeImpl() {
		while segments.count > 0 {
			segments.removeFirst()
		}
		totalCount = 0
	}
	private func prepareSegmentForAdding() {
		guard let last = segments.last else {
			segments.appendLast([:])
			return
		}
		guard last.count < configuration.segmentSize else {
			segments.appendLast([:])
			return
		}
		return ()
	}
}
















