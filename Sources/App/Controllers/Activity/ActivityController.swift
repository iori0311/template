import Hummingbird

/// ジェネリック型でRepositoryという型パラメータを受け取る。repositoryはActivityRepositoryに準拠する必要がある。
struct ActivityController<Repository: ActivityRepository> {
    let repository: Repository

    var endpoints: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(":id", use: get)
            .get(use: getAll)
            .post(use: create)
            .patch(":id", use: update)
            .delete(":id", use: delete)
            .delete(use: deleteAll)
    }

    /// Get Activity endpoint
    ///@Sendable クロージャや関数がスレッドセーフに使用できることを保証するもの
    @Sendable func get(request: Request, context: some RequestContext) async throws -> Activity? {
        let idString: String = try context.parameters.require("id")
        guard let id = Int(idString) else {
        throw HTTPError(.badRequest, message: "Invalid ID format")
    }
        return try await self.repository.get(id: id)
    }

    /// Get All Activity endpoint
    @Sendable func getAll(request: Request, context: some RequestContext) async throws -> [Activity] {
        return try await self.repository.getAll()
    }

    struct CreateRequest: Decodable {
        let title: String
        let description: String
    }

    /// Create activity endpoint
    @Sendable func create(request: Request, context: some RequestContext) async throws -> Activity {
        let request = try await request.decode(as: CreateRequest.self, context: context)
        return try await self.repository.create(title: request.title, description: request.description)
    }

    struct UpdateRequest: Decodable {
        let title: String?
        let description: String?
    }

    /// Update activity endpoint
    @Sendable func update(request: Request, context: some RequestContext) async throws -> Activity? {
        let idString: String = try context.parameters.require("id")
        guard let id = Int(idString) else {
        throw HTTPError(.badRequest, message: "Invalid ID format")
        }
        let request = try await request.decode(as: UpdateRequest.self, context: context)
        guard let activity = try await self.repository.update(
            id: id,
            title: request.title,
            description: request.description
        ) else {
            throw HTTPError(.badRequest)
        }
        return activity
    }

    ///Delete activity endpoint
    @Sendable func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let idString: String = try context.parameters.require("id")
        guard let id = Int(idString) else {
        throw HTTPError(.badRequest, message: "Invalid ID format")
        }
        if try await self.repository.delete(id: id) {
            return .ok
        } else {
            return .badRequest
        }
    }

    /// Delete All activities endpoint
    @Sendable func deleteAll(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        try await self.repository.deleteAll()
        return .ok
    }
}