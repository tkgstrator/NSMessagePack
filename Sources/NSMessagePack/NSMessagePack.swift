import Foundation

/// The MessagePackValue enum encapsulates one of the following types: Nil, Bool, Int, UInt, Float, Double, String, Binary, Array, Map, and Extended.
public enum MessagePackValue {
    case `nil`
    case raw(Data)
    case bool(Bool)
    case int64(Int64)
    case uint64(UInt64)
    case float(Float)
    case double(Double)
    case string(String)
    case binary(Data)
    case array([MessagePackValue])
    case map([MessagePackValue: MessagePackValue])
    case extended(Int8, Data)
}

extension Data {
    var bytes: [UInt8] {
        self.withUnsafeBytes({ (pointer: UnsafeRawBufferPointer) -> [UInt8] in
            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            return [UInt8](UnsafeBufferPointer(start: unsafePointer, count: self.count))
        })
    }

    var toHexString: String {
        bytes.map({ String(format: "%02X", $0) }).joined(separator: " ")
    }
}

extension MessagePackValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nil:
            return "nil"
        case .raw(let value):
            guard let unpacked = try? unpackFirst(value)
            else {
                return "raw(\(value.toHexString))"
            }
            return unpacked.description
        case .bool(let value):
            return "bool(\(value))"
        case .int64(let value):
            return "int(\(value))"
        case .uint64(let value):
            return "uint(\(value))"
        case .float(let value):
            return "float(\(value))"
        case .double(let value):
            return "double(\(value))"
        case .string(let string):
            return "string(\(string))"
        case .binary(let data):
            return "data(\(data))"
        case .array(let array):
            return "array(\(array.description))"
        case .map(let dict):
            return "map(\(dict.description))"
        case .extended(let type, let data):
            return "extended(\(type), \(data))"
        }
    }
}

extension MessagePackValue: Equatable {
    public static func ==(lhs: MessagePackValue, rhs: MessagePackValue) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case (.bool(let lhv), .bool(let rhv)):
            return lhv == rhv
        case (.int64(let lhv), .int64(let rhv)):
            return lhv == rhv
        case (.uint64(let lhv), .uint64(let rhv)):
            return lhv == rhv
        case (.int64(let lhv), .uint64(let rhv)):
            return lhv >= 0 && UInt64(lhv) == rhv
        case (.uint64(let lhv), .int64(let rhv)):
            return rhv >= 0 && lhv == UInt64(rhv)
        case (.float(let lhv), .float(let rhv)):
            return lhv == rhv
        case (.double(let lhv), .double(let rhv)):
            return lhv == rhv
        case (.string(let lhv), .string(let rhv)):
            return lhv == rhv
        case (.binary(let lhv), .binary(let rhv)):
            return lhv == rhv
        case (.array(let lhv), .array(let rhv)):
            return lhv == rhv
        case (.map(let lhv), .map(let rhv)):
            return lhv == rhv
        case (.extended(let lht, let lhb), .extended(let rht, let rhb)):
            return lht == rht && lhb == rhb
        default:
            return false
        }
    }
}

extension MessagePackValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }
    
    public var hashValue: Int {
        switch self {
        case .nil: return 0
        case .raw(let value): return value.hashValue
        case .bool(let value): return value.hashValue
        case .int64(let value): return value.hashValue
        case .uint64(let value): return value.hashValue
        case .float(let value): return value.hashValue
        case .double(let value): return value.hashValue
        case .string(let string): return string.hashValue
        case .binary(let data): return data.count
        case .array(let array): return array.count
        case .map(let dict): return dict.count
        case .extended(let type, let data): return 31 &* type.hashValue &+ data.count
        }
    }
}

public enum MessagePackError: Error {
    case invalidArgument
    case insufficientData
    case invalidData
}
