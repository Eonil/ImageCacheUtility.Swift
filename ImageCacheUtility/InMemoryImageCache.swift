//
//  InMemoryImageCache.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import CoreGraphics

/// This purges itself on system memory pressre event.
public class InMemoryImageCache {
	public init(configuration: GenerationalCacheConfiguration) {
		let killSegment = { (segment: [NSURL:CGImageRef]) -> () in
			for (_, var v) in segment {
				if isUniquelyReferencedNonObjC(&v) {
					// No other one is holding reference to this image.
					dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { [v] in
						// Just hold a strong reference to kill it in non-main thread.
						noop(v)
					}
				}
			}
		}
		imageGenMap = GenerationalCache(configuration: configuration, killSegment: killSegment)
	}
	deinit {
		final class Box { var cache: GenerationalCache<NSURL,CGImageRef>? }
		let box = Box()
		box.cache = imageGenMap
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { [killInNonMainThread = box] in
			// At this point, `self` should be dead, this must be the only reference to cache.
			// Just keep it in non-main thread, so it will clean-up its memory
			// in non-main thread.
			precondition(isUniquelyReferencedNonObjC(&killInNonMainThread.cache))
		}
	}

	// MARK: -
	public func quickImageSearchForURL(url: NSURL, timeConstraint: CFTimeInterval) -> ResultWithTimeConstraint<CGImageRef> {
		return imageGenMap.quickValueSearchForKey(url, timeConstraint: TimeInterval(seconds: timeConstraint))
	}
	public func setImage(image: CGImageRef, forURL url: NSURL) {
		imageGenMap.setValue(image, forKey: url)
	}
	public func performEmergencyPurge() {
		imageGenMap.performEmergencyPurge()
	}

	// MARK: -
	private let imageGenMap: GenerationalCache<NSURL,CGImageRef>
}

private func noop<T: AnyObject>(_: T) {
}