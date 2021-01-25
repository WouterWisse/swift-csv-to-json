import XCTest
@testable import CSVtoJSON

final class CSVtoJSONTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CSVtoJSON().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
