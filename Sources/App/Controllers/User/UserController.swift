import Hummingbird

struct UserController<Repository: UserRepository> {
    private let repository: Repository
    private let userService: UserServiceProtocol
    private let authService: AuthenticationServiceProtocol

    init(
        repository: Repository, userService: UserServiceProtocol,
        authService: AuthenticationServiceProtocol
    ) {
        self.repository = repository
        self.userService = userService
        self.authService = authService
    }

    var endpoints: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(use: getAll)
            .post(use: create)
            .delete(":id", use: delete)
    }

    /// Get All users endpoint
    @Sendable func getAll(request: Request, context: some RequestContext) async throws -> [User] {
        return try await self.repository.getAll()
    }

    struct CreateRequest: Decodable {
        let user_name: String
        let password: String
    }

    /// POST user create
    @Sendable func create(request: Request, context: some RequestContext) async throws
        -> HTTPResponse.Status
    {
        do {
            let request: CreateRequest = try await request.decode(
                as: CreateRequest.self, context: context)
            let hashed_password: String = try userService.hushPassword(password: request.password)
            try await self.repository.create(
                user_name: request.user_name, hashed_password: hashed_password)
            return .ok
        } catch UserServiceError.creatingSaltFailed(let reason) {
            throw HTTPError(HTTPResponse.Status.internalServerError, message: reason)
        } catch RepositoryError.creationFailed(let reason) {
            throw HTTPError(HTTPResponse.Status.badRequest, message: reason)
        } catch {
            throw HTTPError(
                HTTPResponse.Status.internalServerError, message: "Unexpected error: \(error)")
        }
    }

    /// DELETE user delete
    @Sendable func delete(request: Request, context: some RequestContext) async throws
        -> HTTPResponse.Status
    {
        let idString: String = try context.parameters.require("id")
        guard let id = Int(idString) else {
            throw HTTPError(.badRequest, message: "Invalid ID format")
        }
        if try await self.repository.delete(id: id) {
            return .ok
        } else {
            return .notFound
        }
    }
}
