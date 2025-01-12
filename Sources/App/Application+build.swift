import Hummingbird
import Logging
import PostgresNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var inMemoryTesting: Bool { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws
    -> some ApplicationProtocol
{
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "HummingbirdServer")
        logger.logLevel =
            arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap {
                Logger.Level(rawValue: $0)
            } ?? .info
        return logger
    }()

    /// RepositoryをRouterに渡すことで、APIのデータの永続化先をふりわけている、
    let activityRepository: ActivityRepository
    let userRepository: UserRepository
    let router: Router<AppRequestContext>
    let userService: UserServiceProtocol = UserServiceImpl()
    let authService: AuthenticationServiceProtocol = AuthenticationServiceImpl()

    if !arguments.inMemoryTesting {
        let client = PostgresClient(
            configuration: .init(
                /// ローカルで起動する場合は以下
                host: "localhost",
                /// dockerの場合はhostをdbのservice名にする必要がある
                // host: "postgres-db",
                username: "user",
                password: "password",
                database: "my_db",
                tls: .disable),
            backgroundLogger: logger
        )
        activityRepository = ActivityPostgresRepository(client: client, logger: logger)
        userRepository = UserPostgresRepository(client: client, logger: logger)
    } else {
        activityRepository = ActivityMemoryRepository()
        userRepository = UserMemoryRepository()
        print("Call InMemory")
    }

    router = buildRouter(
        activityRepository,
        userRepository,
        userService: userService,
        authService: authService
    )

    var app: Application<RouterResponder<AppRequestContext>> = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "HummingbirdServer"
        ),
        logger: logger
    )

    if !arguments.inMemoryTesting {
        if let pgActivityRepo = activityRepository as? ActivityPostgresRepository {
        app.addServices(pgActivityRepo.client)
    }
        app.beforeServerStarts {
            print("Creating tables...")
            try await (activityRepository as? ActivityPostgresRepository)?.createTable()
            try await (userRepository as? UserPostgresRepository)?.createTable()
            print("Tables created successfully.")
        }
    }
    return app
}

/// Build router
/// Repositoryを受け取るようにする
func buildRouter(
    _ activityRepository: some ActivityRepository,
    _ userRepository: some UserRepository,
    userService: UserServiceProtocol,
    authService: AuthenticationServiceProtocol
) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add default endpoint
    router.get("/") { _, _ in
        return "Hello world!"
    }

    // Add health endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
        return .ok
    }

    router.addRoutes(
        ActivityController(repository: activityRepository).endpoints, atPath: "/activities")
    router.addRoutes(
        UserController(
            repository: userRepository, userService: userService, authService: authService
        ).endpoints, atPath: "/user")
    return router
}
