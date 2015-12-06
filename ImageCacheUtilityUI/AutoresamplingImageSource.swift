//
//  AutoresamplingImageSource.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol RemoteImageSource: class {
	func onReady(continuation: CGImage?->())
}
public enum AutoresamplingImageSource {
	case NonImmediate(RemoteImageSource)
	case Immediate(image: CGImageRef)
}

public func == (a: AutoresamplingImageSource, b: AutoresamplingImageSource) -> Bool {
	switch (a, b) {
	case (.NonImmediate(let a1), .NonImmediate(let b1)):	return a1 === b1
	case (.Immediate(let a1), .Immediate(let b1)):		return a1 === b1
	default:						return false
	}
}
public func != (a: AutoresamplingImageSource, b: AutoresamplingImageSource) -> Bool {
	return (a == b) == false
}
