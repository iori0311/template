import Foundation

protocol ActivityRepository: Sendable {
    func get(id: Int) async throws -> Activity?
    func getAll() async throws -> [Activity]
    func create(title: String, description: String) async throws -> Activity
    func update(id: Int, title: String?, description: String?) async throws -> Activity?
    func delete(id: Int) async throws -> Bool
    func deleteAll() async throws
}