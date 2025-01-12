import Foundation

struct UserMemoryRepository: UserRepository {
    private var users: [Int: User]

    init() {
        self.users = [:]
    }
    func getAll() async throws -> [User] {
            return self.users.values.map { $0 }
    }

    func create(user_name: String, hashed_password: String) async throws {
    }

    func delete(id: Int) async throws -> Bool {
     return true
    }
}