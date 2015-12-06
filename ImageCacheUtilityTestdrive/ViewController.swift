//
//  ViewController.swift
//  ImageCacheUtilityTestdrive
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import UIKit
import ImageCacheUtility
import ImageCacheUtilityUI

class ViewController: UIViewController {
//	let cache = InMemoryImageCache(configuration: GenerationalCacheConfiguration(segmentSize: 16, maxSegmentCount: 16, maxTotalCount: 128))
	let imageView = AutoresamplingImageView()
	let addrDisp = ImageAddressDisplayController()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.whiteColor()
		view.addSubview(imageView)
		addrDisp.imageView = imageView
	}
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		imageView.frame = UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsets(top: 20 + 44 + 30, left: 30, bottom: 30, right: 30))
		imageView.backgroundColor = UIColor.grayColor()
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		addrDisp.URL = NSURL(string: "https://placehold.it/350x150")
		addrDisp.URL = NSURL(string: "https://placehold.it/400x400")
		addrDisp.URL = NSURL(string: "https://placehold.it/350x150")
	}

}

