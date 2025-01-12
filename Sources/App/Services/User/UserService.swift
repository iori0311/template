import Crypto
import Foundation

protocol UserServiceProtocol: Sendable {
    func hushPassword(password: String) throws -> String
}

struct UserServiceImpl: UserServiceProtocol {
    private enum ErrorMessage: String {
        case creatingSaltFailed = "failed to create salt"
    }
    func hushPassword(password: String) throws -> String {
        let salt = try generateSalt()
        let combined = password + salt
        let hashed = hashString(combined)
        return hashed
        // return "\(salt):\(hashed)"
    }

    private func generateSalt() throws -> String {
        do {
        let salt = try generateSecureRandomBytes(count: 16)
        return salt.base64EncodedString()
        } catch {
            throw UserServiceError.creatingSaltFailed(reason: ErrorMessage.creatingSaltFailed.rawValue)
        }
    }

    /// Hash with SHA256
    private func hashString(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

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
