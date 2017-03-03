import XCTest
@testable import model

class modelTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(model().text, "Hello, World!")
    }


    static var allTests : [(String, (modelTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
