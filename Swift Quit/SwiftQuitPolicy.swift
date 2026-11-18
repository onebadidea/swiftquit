import Foundation

enum SwiftQuitPolicy {
    static func normalizedApplicationPath(_ application: String) -> String {
        if application.hasPrefix("file://"),
           let url = URL(string: application)?.standardizedFileURL {
            return url.path
        }

        return URL(fileURLWithPath: application).resolvingSymlinksInPath().standardizedFileURL.path
    }

    static func shouldCloseApplication(
        applicationName: String,
        settings: [String: String],
        excludedApplications: [String]
    ) -> Bool {
        let behaviour = settings["excludeBehaviour"] ?? "excludeApps"
        if behaviour == "excludeApps" {
            return !excludedApplications.contains(applicationName)
        }
        return excludedApplications.contains(applicationName)
    }
}
