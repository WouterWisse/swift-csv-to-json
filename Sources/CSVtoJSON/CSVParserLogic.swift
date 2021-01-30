//
//  CSVParserLogic.swift
//  
//
//  Created by Wouter Wisse on 26/01/2021.
//

import Foundation

public enum CSVParserError: Error {
    case invalidFilePath
    case invalidFileContent
    case csvIsEmpty
    case csvOnlyContainsHeader
    case csvAmountOfColumnsDoNotMatchHeader
}

public enum CSVParserValueSeparator {
    case semicolon
    case custom(string: String)
    
    var value: String {
        switch self {
        case .semicolon: return ";"
        case .custom(string: let string): return string
        }
    }
}

public struct CSVParserOptions {
    let valueSeparator: CSVParserValueSeparator
    let numberDecimalSeparator: String
    let numberThousandSeparator: String?
    let jsonWritingOptions: JSONSerialization.WritingOptions
    
    public init(valueSeparator: CSVParserValueSeparator = .semicolon,
         numberDecimalSeparator: String = ".",
         numberThousandSeparator: String? = nil,
         jsonWritingOptions: JSONSerialization.WritingOptions = .fragmentsAllowed) {
        self.valueSeparator = valueSeparator
        self.numberDecimalSeparator = numberDecimalSeparator
        self.numberThousandSeparator = numberThousandSeparator
        self.jsonWritingOptions = jsonWritingOptions
    }
}

public protocol CSVParserLogic {
    func json(from string: String, options: CSVParserOptions) throws -> String
    func json(from file: String,
              withExtension fileExtension: String,
              inBundle bundle: Bundle,
              options: CSVParserOptions) throws -> String
}

extension CSVParserLogic {
    func json(from string: String, options: CSVParserOptions = CSVParserOptions()) throws -> String {
        try json(from: string, options: options)
    }
    
    func json(from file: String,
              withExtension fileExtension: String = "csv",
              inBundle bundle: Bundle,
              options: CSVParserOptions = CSVParserOptions()) throws -> String {
        try json(from: file, withExtension: fileExtension, inBundle: bundle, options: options)
    }
}

// MARK: CSVParserLogic

public final class CSVParser: CSVParserLogic {
    
    private let numberFormatter: NumberFormatter = NumberFormatter()
    
    public func json(from string: String,
                     options: CSVParserOptions) throws -> String {
        let rows: [String] = string.components(separatedBy: NSCharacterSet.newlines).filter { !$0.isEmpty }
        
        let valueSeparator = options.valueSeparator.value
        
        guard let header = rows.first?.colums(separatedBy: valueSeparator)
            else { throw CSVParserError.csvIsEmpty }
        
        guard rows.count >= 2
            else { throw CSVParserError.csvOnlyContainsHeader }
        
        guard header.count == rows.last?.colums(separatedBy: valueSeparator).count
            else { throw CSVParserError.csvAmountOfColumnsDoNotMatchHeader }
        
        // Drop the first row, that should be the header.
        let dataRows = rows.dropFirst()
        
        // Setup up the NumberFormatter.
        numberFormatter.decimalSeparator = options.numberDecimalSeparator
        if let thousandSeparator = options.numberThousandSeparator {
            numberFormatter.hasThousandSeparators = true
            numberFormatter.thousandSeparator = thousandSeparator
        }
        
        let dictionaries = dataRows.map { row -> Dictionary<String, AnyObject> in
            let stringValues = row.colums(separatedBy: valueSeparator)
            let values = stringValues.map { string -> AnyObject in
                guard let number = numberFormatter.number(from: string) else { return string as AnyObject }
                return number
            }
            return Dictionary(keys: header, values: values)
        }
        
        return dictionaries.toJSONString(options: options.jsonWritingOptions)
    }
    
    public func json(from file: String,
                     withExtension fileExtension: String,
                     inBundle bundle: Bundle = Bundle.main,
                     options: CSVParserOptions) throws -> String {
        let contents = try stringFromFile(bundle: bundle, fileName: file, fileExtension: fileExtension)
        return try json(from: contents, options: options)
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
    func colums(separatedBy separator: String) -> [String] {
        components(separatedBy: separator)
    }
}

private extension Collection where Iterator.Element == [String: AnyObject] {
    func toJSONString(options: JSONSerialization.WritingOptions = .fragmentsAllowed) -> String {
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
