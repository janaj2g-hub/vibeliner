import Foundation

/// Role of an image in a multi-image composite capture.
enum ImageRole: String, Codable {
    case observed
    case expected
    case reference

    var displayName: String {
        switch self {
        case .observed: return "Observed"
        case .expected: return "Expected"
        case .reference: return "Reference"
        }
    }

    static func from(string: String) -> ImageRole {
        switch string.lowercased() {
        case "expected": return .expected
        case "reference": return .reference
        default: return .observed
        }
    }
}
