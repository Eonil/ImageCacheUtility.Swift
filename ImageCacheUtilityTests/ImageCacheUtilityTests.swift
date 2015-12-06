//
//  ImageCacheUtilityTests.swift
//  ImageCacheUtilityTests
//
//  Created by Hoon H. on 2015/12/06.
//
//

import XCTest
@testable import ImageCacheUtility

class ImageCacheUtilityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}

extension ImageCacheUtilityTests {
	func test1() {
		let cache = InMemoryImageCache(configuration: GenerationalCacheConfiguration(segmentSize: 16, maxSegmentCount: 16, maxTotalCount: 16))
		let result = cache.quickImageSearchForURL(NSURL(string: "http://placehold.it/350x150")!, timeConstraint: 0.001)
		XCTAssert(result == .InTime(nil))
	}
}

















