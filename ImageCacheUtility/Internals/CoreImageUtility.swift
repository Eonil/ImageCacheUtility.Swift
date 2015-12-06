//
//  CoreImageUtility.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//  Copyright © 2015 Eonil. All rights reserved.
//

import Foundation
import CoreImage

struct CoreImageUtility {
	static let defaultCPUContext = CIContext(options: [kCIContextUseSoftwareRenderer: false])
}
