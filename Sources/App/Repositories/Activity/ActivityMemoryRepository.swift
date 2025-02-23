import Foundation

/// メモリで管理するレポジトリ

/// Concrete implementation of `AcitivityRepository` that stores everything in memory
/// actorは並行処理に特化したClassの一種である。
actor ActivityMemoryRepository: ActivityRepository {
    private var activities: [Int: Activity]
    private var nextId: Int

    init() {
        self.activities = [:]
        self.nextId = 1 
    }

    /// Create activity
    func create(title: String, description: String) async throws -> Activity {
        let id = nextId
        nextId += 1
        // let url = urlPrefix + "\(id)"
        let activity = Activity(id: id, title: title, description: description)
        self.activities[id] = activity
        return activity
    }

    /// Get activity
    func get(id: Int) async throws -> Activity? {
        return self.activities[id]
    }

    /// get all activities
    func getAll() async throws -> [Activity] {
        return self.activities.values.map { $0 }
    }

    /// Update activity. Returns updated activity if successful
    func update(id: Int, title: String?, description: String?) async throws -> Activity? {
        if var activity = self.activities[id] {
            if let title {
                activity.title = title
            }
            if let description {
                activity.description = description
            }
            self.activities[id] = activity
            return activity
        }
        return nil
    }

    /// Delete activity
    func delete(id: Int) async throws -> Bool{
        if self.activities[id] != nil {
            self.activities[id] = nil
            return true
        }
        return false
    }

    /// Delete all activities
    func deleteAll() async throws {
        self.activities = [:]
        self.nextId = 1 // reset counter
    }
}
