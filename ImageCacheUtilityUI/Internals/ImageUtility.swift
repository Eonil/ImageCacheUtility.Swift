//
//  ImageUtility.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import CoreGraphics
import ImageIO

struct ImageUtility {
	static func resizeImageAtURL(url: NSURL, intoSizeInPixels sizeInPixels: CGSize) -> CGImageRef? {
		// http://nshipster.com/image-resizing/
		if let imageSource = CGImageSourceCreateWithURL(url, nil) {
			let options: [NSString: NSObject] = [
				kCGImageSourceThumbnailMaxPixelSize: max(sizeInPixels.width, sizeInPixels.height),
				kCGImageSourceCreateThumbnailFromImageAlways: true,
			]
			if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) {
				return scaledImage
			}
		}
		return nil
	}
	static func thumbnailOfImageSource(imageSource: CGImageSourceRef, maxSizeInPixels: CGFloat) -> CGImageRef? {
		// http://nshipster.com/image-resizing/
		let options: [NSString: NSObject] = [
			kCGImageSourceThumbnailMaxPixelSize: maxSizeInPixels,
			kCGImageSourceCreateThumbnailFromImageAlways: true,
		]
		if let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) {
			return scaledImage
		}
		return nil
	}
	static func resizeImage(image: CGImageRef, intoSizeInPixels sizeInPixels: CGSize) -> CGImageRef? {
		// http://nshipster.com/image-resizing/
		let width = Int(round(sizeInPixels.width))
		let height = Int(round(sizeInPixels.height))
		let bitsPerComponent = CGImageGetBitsPerComponent(image)
		let bytesPerRow = 0 // Means autoamtic calculation.
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo([.ByteOrderDefault]).rawValue + CGImageAlphaInfo.PremultipliedLast.rawValue
		let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
		CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
		CGContextDrawImage(context, CGRect(origin: CGPointZero, size: sizeInPixels), image)
		let scaledImage = CGBitmapContextCreateImage(context)
		return scaledImage
	}
}






