import Foundation
import Hummingbird

struct Activity {
    var id: Int?
    var title: String
    var description: String
}

extension Activity: ResponseEncodable, Decodable, Equatable {}