//
//  MemoryPressureMonitoringUtility.swift
//  ImageCacheUtility
//
//  Created by Hoon H. on 2015/12/06.
//
//

protocol Purgeable: class {
	func performEmergencyPurge()
}

func registerWeakReferenceToPurgeable<T: Purgeable>(object: T) {
	purgeables.append({ [weak object] in return object! })
}
func deregisterWeakReferenceToPurgeable<T: Purgeable>(object: T) {
	_ = purgeables.removeAtIndex(purgeables.indexOf({ (f: () -> Purgeable) -> Bool in
		return f() === object
	})!)
}

let observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (n: NSNotification) -> Void in
	assertMainThread()
	assert(n.name == UIApplicationDidReceiveMemoryWarningNotification)
	for p in purgeables {
		p().performEmergencyPurge()
	}
}

var purgeables: [()->Purgeable] = []