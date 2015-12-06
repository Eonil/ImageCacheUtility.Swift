//
//  ImageAddressDisplayController.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import ImageIO
import ImageCacheUtility

/// Controls display of URL into a `AutoresamplingImageView`.
/// This also purges cache on system memory pressure notification.
public class ImageAddressDisplayController {
	public static let defaultCacheConfiguration = GenerationalCacheConfiguration(segmentSize: 64, maxSegmentCount: 1024, maxTotalCount: 2048)
	public static let defaultCache = InMemoryImageCache(configuration: defaultCacheConfiguration)
	public static let defaultSearchTimeConstraint = NSTimeInterval(1/60/100)

	public convenience init() {
		let cache = ImageAddressDisplayController.defaultCache
		let stc = ImageAddressDisplayController.defaultSearchTimeConstraint
		self.init(cache: cache, searchTimeConstraint: stc)
	}
	public init(cache: InMemoryImageCache, searchTimeConstraint: NSTimeInterval) {
		self.cache = cache
		self.searchTimeConstraint = searchTimeConstraint
	}

	// MARK: -
	public weak var imageView: AutoresamplingImageView?
	public let searchTimeConstraint: NSTimeInterval
	public var requestTimeout: NSTimeInterval = NSURLSessionConfiguration.defaultSessionConfiguration().timeoutIntervalForRequest
//	public var resourceTimeout: NSTimeInterval = NSURLSessionConfiguration.defaultSessionConfiguration().timeoutIntervalForResource

	public var URL: NSURL? {
		willSet {
		}
		didSet {
			switch (oldValue, URL) {
			case (nil, nil):
				return
			case (nil, _):
				render()
				return
			case (_, nil):
				render()
				return
			case (_, _):
				guard oldValue! != URL! else { return }
				render()
				return
			}
		}
	}

	// MARK: -
	private weak var cache: InMemoryImageCache?
	private func render() {
		if let URL = URL {
			let result = cache!.quickImageSearchForURL(URL, timeConstraint: searchTimeConstraint)
			imageView?.source = {
				switch result {
				case .InTime(let image):
					if let image = image {
						return AutoresamplingImageSource.Immediate(image: image)
					}

				case .OutOfTime:
					break

				}

				final class RemoteImageSourceImpl: RemoteImageSource {
					init(URL: NSURL, requestTimeout: NSTimeInterval) {
						fetchImageAtURL(URL, timeout: requestTimeout, completion: { [weak self] (image) -> () in
							guard self != nil else { return }
							self!.done = true
							self!.result = image
							self!.continuation?(image)
						})
					}
					var done: Bool = false
					var result: CGImageRef?
					var continuation: ((CGImageRef?) -> ())?
					private func onReady(continuation: CGImage? -> ()) {
						precondition(self.continuation == nil)
						if done {
							continuation(result)
						}
						else {
							self.continuation = continuation
						}
					}
				}
				let remoteSource = RemoteImageSourceImpl(URL: URL, requestTimeout: requestTimeout)
				return AutoresamplingImageSource.NonImmediate(remoteSource)
			}()
		}
		else {
			imageView?.source = nil
		}
	}
}

private func fetchImageAtURL(address: NSURL, timeout: NSTimeInterval, completion: (image: CGImageRef?) -> ()) {
	let req = NSURLRequest(URL: address, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: timeout)
	let task = NSURLSession.sharedSession().downloadTaskWithRequest(req) { (url: NSURL?, response: NSURLResponse?, error: NSError?) -> Void in
		GCDUtility.continueInNonMainThread {
			guard let downloadedURL = url else {
				completion(image: nil)
				return
			}
			guard downloadedURL.fileURL else {
				assert(false)
				completion(image: nil)
				return
			}
			// If you set to use memory-mapping explicitly,
			// ImageIO sometimes cannot locate the file on Simulator... 
			// So don't.
			guard let data = NSData(contentsOfURL: downloadedURL) else {
				completion(image: nil)
				return
			}
			guard let source = CGImageSourceCreateWithData(data, nil) else {
				completion(image: nil)
				return
			}
			// ImageIO sometimes cannot load from URL on Simulator... 
			// So just don't.
//			guard let source = CGImageSourceCreateWithURL(downloadedURL, nil) else {
//				completion(image: nil)
//				return
//			}
			guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
				completion(image: nil)
				return
			}
			completion(image: image)
			assert(error == nil, "\(error)")

//			guard let image = CIImage(contentsOfURL: downloadedURL) else {
//				completion(image: nil)
//				return
//			}
//			let image1 = CoreImageUtility.defaultContext.createCGImage(image, fromRect: image.extent)
//			completion(image: image1)
//			assert(error == nil, "\(error)")

//			guard let data = NSData(contentsOfURL: downloadedURL) else {
//				completion(image: nil)
//				return
//			}
//			guard let image = UIImage(data: data) else {
//				completion(image: nil)
//				return
//			}
//			guard let image1 = CGImageCreateCopy(image.CGImage) else {
//				completion(image: nil)
//				return
//			}
//			completion(image: image1)
		}
	}
	task.resume()
}







