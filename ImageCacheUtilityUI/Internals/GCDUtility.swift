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
		dispatch_async(dispatch_get_main_queue(), continuation)
	}
	static func continueInNonMainThread(continuation: ()->()) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
			if NSThread.isMainThread() {
				continueInNonMainThread(continuation)
			}
			else {
				continuation()
			}
		}
	}
}