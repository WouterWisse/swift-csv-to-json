//
//  CSVParserLogic.swift
//  
//
//  Created by Wouter Wisse on 26/01/2021.
//

import Foundation

private enum CSVParserConstants {
    static let csvSeparator = ";"
}

public enum CSVParserError: Error {
    case invalidFilePath
    case invalidFileContent
    case csvIsEmpty
    case csvOnlyContainsHeader
    case csvAmountOfColumnsDoNotMatchHeader
}

public protocol CSVParserLogic {
    func json(from string: String, withOptions options: JSONSerialization.WritingOptions) throws -> String
    func json(from file: String,
              withExtension fileExtension: String,
              inBundle bundle: Bundle,
              withOptions options: JSONSerialization.WritingOptions) throws -> String
}

// MARK: CSVParserLogic

public final class CSVParser: CSVParserLogic {
    
    public func json(from string: String, withOptions options: JSONSerialization.WritingOptions = .prettyPrinted) throws -> String {
        let rows: [String] = string.components(separatedBy: NSCharacterSet.newlines).filter { !$0.isEmpty }
        
        guard let header = rows.first else { throw CSVParserError.csvIsEmpty }
        guard rows.count >= 2 else { throw CSVParserError.csvOnlyContainsHeader }
        guard header.count == rows.last?.count else { throw CSVParserError.csvAmountOfColumnsDoNotMatchHeader }
        
        // Use header components as keys.
        let keys = header.components(separatedBy: CSVParserConstants.csvSeparator)
        
        // Drop the first row, that should be the header.
        let valueRows = rows.dropFirst()
        
        let dictionaries = valueRows.map { row -> Dictionary<String, AnyObject> in
            let stringValues = row.components(separatedBy: CSVParserConstants.csvSeparator)
            let values = stringValues.map { string -> AnyObject in
                guard string.isNumber else { return string as AnyObject }
                return string.isDecimalNumber ? Double(string) as AnyObject : Int(string) as AnyObject
            }
            return Dictionary(keys: keys, values: values)
        }
        
        return dictionaries.toJSONString(options: options)
    }
    
    public func json(from file: String,
                     withExtension fileExtension: String = "csv",
                     inBundle bundle: Bundle = Bundle.main,
                     withOptions options: JSONSerialization.WritingOptions = .prettyPrinted) throws -> String {
        let contents = try stringFromFile(bundle: bundle, fileName: file, fileExtension: fileExtension)
        return try json(from: contents, withOptions: options)
    }
}

// MARK: Private

private extension CSVParser {
    
    func stringFromFile(bundle: Bundle, fileName: String, fileExtension: String) throws -> String {
        guard let filePath = bundle.path(forResource: fileName, ofType: fileExtension) else { throw CSVParserError.invalidFilePath }

        do {
            let contents = try String(contentsOfFile: filePath, encoding: .utf8)
            return contents
        } catch {
            throw CSVParserError.invalidFileContent
        }
    }
}

// MARK: Extensions

private extension String  {
    var isNumber: Bool {
        !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isDecimalNumber: Bool {
        Int(Double(self)!) != Int(self)
    }
}

private extension Collection where Iterator.Element == [String: AnyObject] {
    
    func toJSONString(options: JSONSerialization.WritingOptions = .prettyPrinted) -> String {
        if let array = self as? [[String: AnyObject]],
           let data = try? JSONSerialization.data(withJSONObject: array, options: options),
           let string = String(data: data, encoding: String.Encoding.utf8) {
            return string
        }
        return "[]"
    }
}

private extension Dictionary {

    init(keys: [Key], values: [Value]) {
        precondition(keys.count == values.count, "Keys and Values should match in count.")
        self.init()

        for (index, key) in keys.enumerated() {
            self[key] = values[index]
        }
    }
}
