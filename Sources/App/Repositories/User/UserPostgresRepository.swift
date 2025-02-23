import Foundation
import PostgresNIO

struct UserPostgresRepository: UserRepository {
    let client: PostgresClient
    let logger: Logger

    private enum ErrorMessage: String {
        case creationFailed = "failed to create"
    }

    func createTable() async throws {
        try await self.client.query(
            """
            CREATE TABLE IF NOT EXISTS users (
            "id" SERIAL PRIMARY KEY,
            "user_name" TEXT NOT NULL,
            "hashed_password" TEXT NOT NULL,
            "salt" TEXT NOT NULL
            )
            """,
            logger: logger)
    }

    /// Get all users
    func getAll() async throws -> [User] {
        let stream = try await self.client.query(
            """
                SELECT "id", "user_name", "hashed_password", "salt" from users
            """, logger: logger
        )
        var users: [User] = []
        for try await (id, user_name, hashed_password, salt) in stream.decode(
            (Int, String, String, String).self, context: .default)
        {
            let user: User = User(id: id, user_name: user_name, hashed_password: hashed_password, salt: salt)
            users.append(user)
        }
        return users
    }

    func create(user_name: String, hashed_password: String, salt: String) async throws {
        do {
        try await self.client.query(
            /// プレースホルダーを使うこと
            "INSERT INTO users (user_name, hashed_password, salt) VALUES (\(user_name), \(hashed_password), \(salt))",
            logger: logger)
        } catch {
            throw RepositoryError.creationFailed(reason: ErrorMessage.creationFailed.rawValue)
        }
    }

    func delete(id: Int) async throws -> Bool {
        let selectStream = try await self.client.query(
            """
                SELECT "id" FROM users WHERE "id" = \(id)
            """, logger: logger)

        if try await selectStream.decode((Int).self, context: .default).first(where: { _ in true })
            == nil
        {
            return false
        }
        try await client.query("DELETE FROM users Where id = \(id)", logger: logger)
        return true
    }
}