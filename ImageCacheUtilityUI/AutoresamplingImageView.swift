//
//  AutoresamplingImageView.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

/// If image is huge, it's not only a waste of memory,
/// also consumes several processing resources constantly.
/// Even further, those large images doesn't look good even with GPU filtering
/// that takes significant GPU processing load.
/// It's better to use properly resized image at pixel-level for each view.
///
/// This view takes an image address as URL, and resamples it BEFORE rendering.
/// - If view frame changes, this will reload a newly resampled image.
/// - Resampled image will be cached in memory and erased automatically on 
///   memory pressure.
public class AutoresamplingImageView: UIView {
	public typealias ReloadImageAtURLDelegate = (address: NSURL, completion: (image: CGImageRef?) -> ()) -> ()

	// MARK: -
	public override init(frame: CGRect) {
		super.init(frame: frame)
		contentMode = .ScaleAspectFill
		layer.addSublayer(imageDisplayLayer)
	}
	public required init?(coder aDecoder: NSCoder) {
		fatalError("We do not support IB/SB.")
	}

	// MARK: -
	/// If this is `true`, this view will remove displaying image
	/// when you set source to a new one.
	/// If this is `false`, this view does not replace displaying
	/// at source replacement until the source image to be fully
	/// downloaded.
	public var clearImageImmediatelyOnSourceReplacement: Bool = true

	/// If this is set to non-`nil` value, this view assumes this
	/// view will be placed on the screen eventually, and resamples
	/// image to fit into the screen. If you place this view onto
	/// another screen, program will crash.
	/// Default value is `nil` which means no assumption.
	public var targetScreen: UIScreen?

	/// Setting to an equal source value will be ignored so won't 
	/// trigger replacement of image.
	/// Loading can be asynchronous if no cached image could be found.
	/// Asynchronous loading operation is built with multiple stages,
	/// and will be cancelled as early as possible if you reset 
	/// source to another value.
	public var source: AutoresamplingImageSource? {
		didSet {
			assertMainThread()
			switch (oldValue, source) {
			case (nil, nil):
				return
			case (_, nil):
				render()
				return
			case (nil, _):
				render()
				return
			case (_, _):
				guard oldValue! != source! else { return }
				render()
			}
		}
	}

	// MARK: -
	public static let supportedContentModes = Set<UIViewContentMode>([
		.ScaleAspectFill,
		.ScaleAspectFit,
		])
	public override var contentMode: UIViewContentMode {
		willSet {
			precondition(AutoresamplingImageView.supportedContentModes.contains(newValue), "Unsupported content mode.")
		}
		didSet {
			render()
		}
	}
	public override func willMoveToWindow(newWindow: UIWindow?) {
		super.willMoveToWindow(newWindow)
		precondition(targetScreen == nil || newWindow == nil || targetScreen! == newWindow!.screen)
	}
	public override func didMoveToWindow() {
		super.didMoveToWindow()
		render()
	}
	public override func layoutSubviews() {
		super.layoutSubviews()
		render()
	}

	// MARK: -
	private let imageDisplayLayer = CALayer()
	private var tagForCurrentLoading: ImageResettingOperationIdentifier?
	private func render() {
		func mapContentModeForLayer(mode: UIViewContentMode) -> String {
			switch mode {
			case .ScaleAspectFit:	return kCAGravityResizeAspect
			case .ScaleAspectFill:	return kCAGravityResizeAspectFill
			default:		fatalError("Unsupported content mode.")
			}
		}
		imageDisplayLayer.frame = layer.bounds
		imageDisplayLayer.contentsGravity = mapContentModeForLayer(contentMode)
		guard let _ = windowScreenScale() else {
			tagForCurrentLoading = nil
			imageDisplayLayer.contents = nil
			return
		}
		if imageExactlyFitsToBoundsInScreen() == false {
			resetImageBySource()
		}
	}
	private func resetImageBySource() {
		precondition(windowScreenScale() != nil)
		let tag = ImageResettingOperationIdentifier()
		tagForCurrentLoading = tag
		guard let source = source else {
			setDisplayingImageFinally(nil)
			return
		}
		switch source {
		case .Immediate(let image):
			setImageWithResamplingAsynchronously(image, tag: tag)
		case .NonImmediate(let source):
			source.onReady { [weak self] (image: CGImageRef?) -> () in
				guard self != nil else { return }
				guard tag === self!.tagForCurrentLoading else { return }
				guard let image = image else {
					self!.setDisplayingImageFinally(nil)
					return
				}
				GCDUtility.continueInMainThread { [weak self] in
					guard self != nil else { return }
					// We cannot use `CGImageSourceCreateThumbnailAtIndex` because support
					// for `ScaleAspectFill` is required.
					self!.setImageWithResamplingAsynchronously(image, tag: tag)
				}
			}

		}
	}
	private func setImageWithResamplingAsynchronously(image: CGImageRef, tag: ImageResettingOperationIdentifier) {
		precondition(windowScreenScale() != nil)
		let fittingSizeInPixels = fittingImageSizeInPixels(image)
		GCDUtility.continueInQueue(theImageProcessingSerialQueue) { [weak self, bounds, contentMode] in
			let image1 = ImageUtility.resizeImage(image, intoSizeInPixels: fittingSizeInPixels)
			assert(image1 != nil, "Could not load image.")
			GCDUtility.continueInMainThread { [weak self] in
				guard self != nil else { return }
				guard self!.tagForCurrentLoading === tag else {
					return
				}
				guard self!.bounds.size == bounds.size else {
					self!.setImageWithResamplingAsynchronously(image, tag: tag)
					return
				}
				guard self!.contentMode == contentMode else {
					self!.setImageWithResamplingAsynchronously(image, tag: tag)
					return
				}
				self!.setDisplayingImageFinally(image1)
			}
		}
	}
	private func setDisplayingImageFinally(image: CGImageRef?) {
		precondition(tagForCurrentLoading !== nil)
		tagForCurrentLoading = nil
		imageDisplayLayer.contents = image
	}

	// MARK: -
	private func imageExactlyFitsToBoundsInScreen() -> Bool {
		precondition(windowScreenScale() != nil)
		guard let contents = imageDisplayLayer.contents else { return false }
		if contents is CGImageRef == false { return false }
		let image = contents as! CGImageRef
		let w = CGImageGetWidth(image)
		let h = CGImageGetHeight(image)
		let fittingSizeInPixels = fittingImageSizeInPixels(image)
		let fitW = w == Int(round(fittingSizeInPixels.width))
		let fitH = h == Int(round(fittingSizeInPixels.height))
		return fitW && fitH
	}
	private func fittingImageSizeInPixels(image: CGImageRef) -> CGSize {
		precondition(windowScreenScale() != nil)
		guard let scale = windowScreenScale() else { fatalError() }
		let boundsSizeInPixels = bounds.size * scale
		let imageW = CGImageGetWidth(image)
		let imageH = CGImageGetHeight(image)
		let imageToBoundsRatioInX = max(1, boundsSizeInPixels.width / CGFloat(imageW)) // Do not make it bigger.
		let imageToBoundsRatioInY = max(1, boundsSizeInPixels.height / CGFloat(imageH)) // Do not make it bigger.
		let maxRatio = max(imageToBoundsRatioInX, imageToBoundsRatioInY)
		let minRatio = min(imageToBoundsRatioInX, imageToBoundsRatioInY)
		switch contentMode {
		case .ScaleAspectFit:	return bounds.size * minRatio
		case .ScaleAspectFill:	return bounds.size * maxRatio
		default:		fatalError()
		}
	}
	private func windowScreenScale() -> CGFloat? {
		return (targetScreen ?? window?.screen)?.scale
	}
}

private let theImageProcessingSerialQueue = dispatch_queue_create("SERIAL IMAGE RESIZING QUEUE", DISPATCH_QUEUE_SERIAL)!

private final class ImageResettingOperationIdentifier {}


















