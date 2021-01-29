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
        brand;model;year
        Ferrari;LaFerrari;2013
        McLaren;P1;2013
        Porsche;918 Spyder;2013
        """
        
        // When
        let json = try? sut.json(from: csvString, withOptions: .fragmentsAllowed)
        
        // Then
        XCTAssertNotNil(json)
    }
    
    func test_json_withStringWithDecimalNumber_shouldReturnValidJSON() {
        // Given
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = ","
        sut = CSVParser(numberFormatter: numberFormatter)
        
        let csvString = """
        brand;model;price
        Ferrari;LaFerrari;1000000,00
        """
        
        // When
        struct Car: Codable {
            let brand: String
            let model: String
            let price: Double
        }
        
        let json = try! sut.json(from: csvString, withOptions: .fragmentsAllowed)
        let jsonData = json.data(using: .utf8)!
        let cars: [Car] = try! JSONDecoder().decode([Car].self, from: jsonData)
        
        // Then
        XCTAssertEqual(cars.count, 1)
        XCTAssertEqual(cars[0].brand, "Ferrari")
        XCTAssertEqual(cars[0].model, "LaFerrari")
        XCTAssertEqual(cars[0].price, 1_000_000)
    }
    
    func test_json_withOnlyHeaderString_shouldThrowError() {
        // Given
        let csvString = """
        brand;model;year
        """
        
        // When & Then
        XCTAssertThrowsError(try sut.json(from: csvString, withOptions: .fragmentsAllowed)) { error in
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
        brand;model;year
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

private extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "nl_NL")
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        return components.date!
    }
}
