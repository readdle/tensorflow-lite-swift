import XCTest
@testable import TensorFlowLite

final class TensorFlowLiteTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Runtime.version, "2.15.0")
    }
}