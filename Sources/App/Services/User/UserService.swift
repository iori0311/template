import Crypto
import Foundation

protocol UserServiceProtocol: Sendable {
    func createUser(userName: String, password: String) async throws
    func deleteUser(id: Int) async throws -> Bool
    func getAllUsers() async throws -> [User]
    func hashPassword(password: String, withSalt: String) throws -> String
}

struct UserServiceImpl: UserServiceProtocol {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func createUser(userName: String, password: String) async throws {
        let salt = try generateSalt()
        let hashedPassword = hashString(password + salt)
        try await userRepository.create(
            user_name: userName,
            hashed_password: hashedPassword,
            salt: salt
        )
    }

    func deleteUser(id: Int) async throws -> Bool {
        return try await userRepository.delete(id: id)
    }

    func getAllUsers() async throws -> [User] {
        return try await userRepository.getAll()
    }

    func hashPassword(password: String, withSalt salt: String) -> String {
        return hashString(password + salt)
    }

    private func generateSalt() throws -> String {
        do {
            let salt = try generateSecureRandomBytes(count: 16)
            return salt.base64EncodedString()
        } catch {
            throw UserServiceError.creatingSaltFailed(reason: "Failed to create salt")
        }
    }

    private func hashString(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// for generating salt
    private func generateSecureRandomBytes(count: Int) throws -> Data {
        var data = Data(count: count)
        let result = data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return -1
            }
            return read(RandomFileDescriptor.urandom, baseAddress, count)
        }

        guard result == count else {
            throw NSError(domain: "RandomGenerationError", code: 1, userInfo: nil)
        }
        return data
    }

    private enum RandomFileDescriptor {
        static let urandom = open("/dev/urandom", O_RDONLY)
    }
}
