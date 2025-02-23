import Hummingbird

struct UserController {
    private let userService: UserServiceProtocol

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    var endpoints: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(use: getAll)
            .post(use: create)
            .delete(":id", use: delete)
    }

    struct CreateRequest: Decodable {
        let user_name: String
        let password: String
    }

    /// Get All users endpoint
    @Sendable func getAll(request: Request, context: some RequestContext) async throws -> [User] {
        return try await self.userService.getAllUsers()
    }

    /// POST user create
    @Sendable func create(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let request: CreateRequest = try await request.decode(as: CreateRequest.self, context: context)
        try await self.userService.createUser(userName: request.user_name, password: request.password)
        return .ok
    }

    /// DELETE user delete
    @Sendable func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let idString: String = try context.parameters.require("id")
        guard let id = Int(idString) else {
            throw HTTPError(.badRequest, message: "Invalid ID format")
        }
        if try await self.userService.deleteUser(id: id) {
            return .ok
        } else {
            return .notFound
        }
    }
}
