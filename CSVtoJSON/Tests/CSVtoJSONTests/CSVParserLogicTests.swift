import XCTest
@testable import CSVtoJSON

final class CSVtoJSONTests: XCTestCase {
    
    var sut: CSVParserLogic!
    
    override func setUpWithError() throws {
        sut = CSVParser()
    }
    
    // MARK: Tests
    
    func test_json_withString_shouldReturnValidJSON() {
        // Given
        let csvString = """
        Brand;Model;Launch year
        Ferrari;LaFerrari;2013
        McLaren;P1;2013
        Porsche;918 Spyder;2013
        """
        
        // When
        let json = try? sut.json(from: csvString, withOptions: .prettyPrinted)
        
        // Then
        XCTAssertNotNil(json)
    }
    
    func test_json_withOnlyHeaderString_shouldThrowError() {
        // Given
        let csvString = """
        Brand;Model;Launch year
        """
        
        // When & Then
        XCTAssertThrowsError(try sut.json(from: csvString, withOptions: .prettyPrinted)) { error in
            XCTAssertEqual(error as? CSVParserError, CSVParserError.csvOnlyContainsHeader)
        }
    }
    
    func test_json_withEmptyString_shouldThrowError() {
        // Given
        let csvString = ""
        
        // When & Then
        XCTAssertThrowsError(try sut.json(from: csvString, withOptions: .prettyPrinted)) { error in
            XCTAssertEqual(error as? CSVParserError, CSVParserError.csvIsEmpty)
        }
    }
    
    func test_json_withHeaderWithNonMatchingColumns_shouldThrowError() {
        // Given
        let csvString = """
        Brand;Model;Launch year
        Ferrari;LaFerrari;2013;Italy
        McLaren;P1;2013;UK
        Porsche;918 Spyder;2013;Germany
        """
        
        // When & Then
        XCTAssertThrowsError(try sut.json(from: csvString, withOptions: .prettyPrinted)) { error in
            XCTAssertEqual(error as? CSVParserError, CSVParserError.csvAmountOfColumnsDoNotMatchHeader)
        }
    }
}
