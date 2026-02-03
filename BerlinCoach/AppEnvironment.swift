import Foundation

struct AppEnvironment {
    static let useMockApi: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["USE_MOCK_API"] == "1"
        #else
        return false
        #endif
    }()
    static let apiBaseURL = URL(string: "https://travis-macbook-pro-14-m2pro.tail1cfafc.ts.net")!

    static let apiClient: APIClientProtocol = {
        #if DEBUG
        if useMockApi {
            return MockAPIClient()
        }
        #endif
        return APIClient(baseURL: apiBaseURL)
    }()
}
