import XCTest

import xcode_parallel_testTests

var tests = [XCTestCaseEntry]()
tests += xcode_parallel_testTests.allTests()
XCTMain(tests)
