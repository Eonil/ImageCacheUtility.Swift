//
//  CoreGraphicsExtensions.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import CoreGraphics

func * (a: CGSize, b: CGFloat) -> CGSize {
	return CGSize(width: a.width * b, height: a.height * b)
}