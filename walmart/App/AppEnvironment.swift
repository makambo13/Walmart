import Foundation

/// Chooses which country service the app runs against.
///
/// Debug builds understand two launch arguments so UI tests (and scripted
/// simulator runs) never depend on the network:
/// - `-UITestStubFeed` serves the bundled sample countries.
/// - `-UITestFailFirstLoad` does the same, but the first request fails.
enum AppEnvironment {
    static func makeService() -> any CountryServicing {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-UITestFailFirstLoad") {
            return StubCountryService(failFirstLoad: true)
        }
        if arguments.contains("-UITestStubFeed") {
            return StubCountryService()
        }
        #endif
        return CountryService()
    }
}
