import Foundation
import PostgresNIO

struct ActivityPostgresRepository: ActivityRepository {
    let client: PostgresClient
    let logger: Logger

    /// Create Activity Table
    func createTable() async throws {
        print("Call createTable")
        try await self.client.query(
            """
            CREATE TABLE IF NOT EXISTS activities (
            "id" SERIAL PRIMARY KEY,
            "title" TEXT NOT NULL,
            "description" TEXT NOT NULL
            )
            """,
            logger: logger)
        print("Done createTable")
    }

    /// Create activity
    func create(title: String, description: String) async throws -> Activity {
        try await self.client.query(
            /// 以下はSQL INJECTIONのリスクがある。
            "INSERT INTO activities (title, description) VALUES (\(title), \(description))",
            /// プレースホルダを用いて記述する。ひたすらエラー出るから一旦放置。
            // "INSERT INTO activities (title, description) VALUES ($1, $2)",
            // [
            //     PostgresData(string: title),
            //     PostgresData(string: description),
            // ],
            logger: logger
        )
        return Activity(title: title, description: description)
    }

    /// Get activity
    func get(id: Int) async throws -> Activity? {
        let stream = try await self.client.query(
            """
                SELECT "id", "title", "description" FROM activities WHERE "id" = \(id)
            """, logger: logger)
        for try await (id, title, description) in stream.decode(
            (Int, String, String).self, context: .default)
        {
            return Activity(id: id, title: title, description: description)
        }
        return nil
    }

    /// Get all activity
    func getAll() async throws -> [Activity] {
        let stream = try await self.client.query(
            """
                SELECT "id", "title", "description" from activities
            """, logger: logger
        )
        var activities: [Activity] = []
        for try await (id, title, description) in stream.decode(
            (Int, String, String).self, context: .default)
        {
            let activity: Activity = Activity(id: id, title: title, description: description)
            activities.append(activity)
        }
        return activities
    }

    /// Update activity. Returns updated activity if successful
    func update(id: Int, title: String?, description: String?) async throws -> Activity? { nil }

    /// Delete activity
    func delete(id: Int) async throws -> Bool {
        let selectStream = try await self.client.query(
            """
                SELECT "id" FROM activities WHERE "id" = \(id)
            """, logger: logger)

        if try await selectStream.decode((Int).self, context: .default).first(where: { _ in true })
            == nil
        {
            return false
        }
        try await client.query("DELETE FROM activities Where id = \(id)", logger: logger)
        return true
    }

    /// Delete all activities
    func deleteAll() async throws {
        try await self.client.query("DELETE FROM activities", logger: logger)
    }
}
