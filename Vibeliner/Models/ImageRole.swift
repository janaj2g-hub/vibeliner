import Foundation

/// Role of an image in a multi-image composite capture.
/// VIB-322: Converted from enum to struct for dynamic custom roles.
struct ImageRole: Codable, Equatable, Hashable {
    let name: String

    var displayName: String { name }

    /// Default roles — backward-compatible static constants.
    static let observed = ImageRole(name: "Observed")
    static let expected = ImageRole(name: "Expected")
    static let reference = ImageRole(name: "Reference")

    init(name: String) {
        self.name = name
    }

    /// Create an ImageRole from a string, matching against configured roles.
    static func from(string: String) -> ImageRole {
        let roles = ConfigManager.shared.roles
        if let match = roles.first(where: { $0.name.lowercased() == string.lowercased() }) {
            return ImageRole(name: match.name)
        }
        // Capitalize first letter for display
        let capitalized = string.isEmpty ? "Observed" : (string.prefix(1).uppercased() + string.dropFirst())
        return ImageRole(name: capitalized)
    }

    /// The color hex for this role from ConfigManager, or purple default.
    var colorHex: String {
        let roles = ConfigManager.shared.roles
        return roles.first(where: { $0.name.lowercased() == name.lowercased() })?.colorHex ?? "#AFA9EC"
    }

    // MARK: - Codable (encode/decode as name string)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ImageRole.from(string: raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name.lowercased())
    }
}
