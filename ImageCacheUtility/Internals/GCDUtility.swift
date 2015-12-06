//
//  GCDUtility.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

struct GCDUtility {
	static func continueInQueue(queue: dispatch_queue_t, continuation: ()->()) {
		dispatch_async(queue, continuation)

	}
	static func continueInMainThread(continuation: ()->()) {
		
	}
	static func continueInNonMainThread(continuation: ()->()) {

	}
}