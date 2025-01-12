import Foundation

protocol AuthenticationServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> String // JWT Token
    func verifyToken(token: String) async throws -> Bool
}

struct AuthenticationServiceImpl: AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> String {
        return "token"
    }

    func verifyToken(token: String) throws -> Bool {
        return true
    }
}