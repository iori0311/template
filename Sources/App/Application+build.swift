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
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "HummingbirdServer_pack")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()

    /// RepositoryをRouterに渡すことで、APIのデータの永続化先をふりわけている、
    var postgresRepository: ActivityPostgresRepository?
    let router: Router<AppRequestContext>
    if !arguments.inMemoryTesting {
        let client = PostgresClient(
                configuration: .init(
                    /// ローカルで起動する場合は以下
                    // host: "localhost",
                    /// dockerの場合はhostをdbのservice名にする必要がある
                    host: "postgres-db",
                    username: "user",
                    password: "password",
                    database: "my_db",
                    tls: .disable),
                backgroundLogger: logger
            )
        let repository: ActivityPostgresRepository = ActivityPostgresRepository(client: client, logger: logger)
        postgresRepository = repository
        router = buildRouter(repository)
        print("Call PostgreSQL")
    } else {
        router = buildRouter(ActivityMemoryRepository())
        print("Call InMemory")
    }

    var app: Application<RouterResponder<AppRequestContext>> = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "HummingbirdServer_pack"
        ),
        logger: logger
    )
    if let postgresRepository: ActivityPostgresRepository {
        app.addServices(postgresRepository.client)
        app.beforeServerStarts {
            try await postgresRepository.createTable()
        }
    }
    return app
}

/// Build router
/// Repositoryを受け取るようにする
func buildRouter(_ repository: some ActivityRepository) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add default endpoint
    router.get("/") { _,_ in
        return "Hello world!"
    }

    // Add health endpoint
    router.get("/health") {_, _ -> HTTPResponse.Status in
        return .ok
    }

    router.get("/getMock") { _, _ in
        return #"""
        [
            {
                "id": 1,
                "title": "Running 1",
                "description": "My desc 1"
            },
            {
                "id": 2,
                "title": "Running 2",
                "description": "My desc 2"
            },
            {
                "id": 3,
                "title": "Running 3",
                "description": "My desc 3"
            }
        ]
        """#
    }
    router.addRoutes(ActivityController(repository: repository).endpoints, atPath: "/activities")
    return router
}
