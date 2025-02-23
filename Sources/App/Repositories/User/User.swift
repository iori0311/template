import Foundation
import Hummingbird

struct User {
    var id: Int?
    var user_name: String
    var hashed_password: String
    var salt: String
}

extension User: ResponseEncodable, Decodable, Equatable {}
