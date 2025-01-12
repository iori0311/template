import Foundation

protocol UserRepository: Sendable {
    func getAll() async throws -> [User]
    func create(user_name: String, hashed_password: String) async throws
    func delete(id: Int) async throws -> Bool
}