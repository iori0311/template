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

/// PostgreSQLConnectionConfiguration
struct PostgresConfiguration {
    let host: String
    let username: String
    let password: String
    let database: String

    static func fromEnvironment(_ environment: Environment) -> Self {
        return .init(
            host: environment.get("POSTGRES_HOST") ?? "postgres-db",
            username: environment.get("POSTGRES_USER") ?? "user",
            password: environment.get("POSTGRES_PASSWORD") ?? "password",
            database: environment.get("POSTGRES_DB") ?? "my_db"
        )
    }
}

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws
    -> some ApplicationProtocol
{
    let environment = Environment()

    // create logger
    let logger = makeLogger(arguments, environment)

    // create repositories
    let (activityRepository, userRepository, maybeClient) = makeRepositories(
        arguments: arguments,
        environment: environment,
        logger: logger
    )

    // prepare services
    let userService: UserServiceProtocol = UserServiceImpl(userRepository: userRepository)

    // create router
    let router: Router<AppRequestContext> = buildRouter(
        activityRepository,
        userService
    )

    // create application
    var app: Application<RouterResponder<AppRequestContext>> = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "HummingbirdServer"
        ),
        logger: logger
    )

    // postgres 
    if let client = maybeClient {
        app.addServices(client)
        app.beforeServerStarts {
            print("Creating tables...")
            try await (activityRepository as? ActivityPostgresRepository)?.createTable()
            try await (userRepository as? UserPostgresRepository)?.createTable()
            print("Tables created successfully.")
        }
    }
    return app
}

private func makeLogger(_ arguments: some AppArguments, _ environment: Environment) -> Logger {
    var logger = Logger(label: "HummingbirdServer")
    logger.logLevel =
        arguments.logLevel
        ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) }
        ?? .info
    return logger
}

private func makeRepositories(
    arguments: some AppArguments,
    environment: Environment,
    logger: Logger
) -> (ActivityRepository, UserRepository, PostgresClient?) {

    if !arguments.inMemoryTesting {
        let pgConfig = PostgresConfiguration.fromEnvironment(environment)
        let client = PostgresClient(
            configuration: .init(
                host: pgConfig.host,
                username: pgConfig.username,
                password: pgConfig.password,
                database: pgConfig.database,
                tls: .disable
            ),
            backgroundLogger: logger
        )
        let activityRepo = ActivityPostgresRepository(client: client, logger: logger)
        let userRepo = UserPostgresRepository(client: client, logger: logger)
        return (activityRepo, userRepo, client)
    } else {
        let activityRepo = ActivityMemoryRepository()
        let userRepo = UserMemoryRepository()
        return (activityRepo, userRepo, nil)
    }
}

/// Build router
private func buildRouter(
    _ activityRepository: some ActivityRepository,
    _ userService: UserServiceProtocol
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

    // Add activity endpoint
    router.addRoutes(
        ActivityController(
            repository: activityRepository
        )
        .endpoints,
        atPath: "/activities")

    // Add user endpoint
    router.addRoutes(
        UserController(
            userService: userService
        ).endpoints,
        atPath: "/user")
    return router
}