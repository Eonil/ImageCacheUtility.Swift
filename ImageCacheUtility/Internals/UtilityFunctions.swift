//
//  UtilityFunctions.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation

@noreturn
func MARK_unimplemented() {
	fatalError()
}

func assertMainThread() {
	assert(NSThread.isMainThread())
}
