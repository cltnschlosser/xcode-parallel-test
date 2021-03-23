import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xcode_parallel_testTests.allTests),
    ]
}
#endif
