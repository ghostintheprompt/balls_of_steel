import Foundation

// Generic API Response wrapper for Schwab API responses
struct APIResponse<T: Codable>: Codable {
    let data: T
    let status: String?
    let message: String?
    
    // For cases where the API returns data directly
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let directData = try? container.decode(T.self) {
            self.data = directData
            self.status = nil
            self.message = nil
        } else {
            let wrapper = try decoder.container(keyedBy: CodingKeys.self)
            self.data = try wrapper.decode(T.self, forKey: .data)
            self.status = try wrapper.decodeIfPresent(String.self, forKey: .status)
            self.message = try wrapper.decodeIfPresent(String.self, forKey: .message)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case data, status, message
    }
}
