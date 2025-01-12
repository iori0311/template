import ArgumentParser
import Hummingbird
import Logging

/// @Optionはコマンドラインから渡される値を処理するためのもの
@main
struct AppCommand: AsyncParsableCommand, AppArguments {
    @Option(name: .shortAndLong)
    var hostname: String = "0.0.0.0"
    // var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8080

    /// logLevelは Logger.loglevel型なので下部のようにコマンドライン引数として利用できるように拡張する必要がある。
    @Option(name: .shortAndLong)
    var logLevel: Logger.Level?

    /// このフラグでどのRepositoryを使うかを決定する
    @Flag
    var inMemoryTesting: Bool = false

    func run() async throws {
        print("App Run")
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

/// Extend `Logger.Level` so it can be used as an argument
/// コマンドライン引数として利用できるように拡張しているらしい。
#if hasFeature(RetroactiveAttribute)
    extension Logger.Level: @retroactive ExpressibleByArgument {}
#else
    extension Logger.Level: ExpressibleByArgument {}
#endif
