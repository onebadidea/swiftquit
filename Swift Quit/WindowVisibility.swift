import CoreGraphics
import Foundation

/// Reads the WindowServer rather than relying on an accessibility client's cached window list.
/// That cache can contain hidden controller windows after an app's user-facing window closes.
enum WindowVisibility {
    struct Record: Equatable {
        let ownerPID: pid_t
        let layer: Int
        let alpha: Double
    }

    static func hasUserVisibleWindow(for processIdentifier: pid_t) -> Bool {
        // Preserve the previous conservative behavior if WindowServer cannot be queried.
        userVisibleApplicationProcessIdentifiers()?.contains(processIdentifier) ?? true
    }

    static func userVisibleApplicationProcessIdentifiers() -> Set<pid_t>? {
        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        return Set(
            windowInfo
                .compactMap(Record.init(windowInfo:))
                .filter { $0.layer == 0 && $0.alpha > 0 }
                .map(\.ownerPID)
        )
    }

    static func hasUserVisibleWindow(for processIdentifier: pid_t, in records: [Record]) -> Bool {
        records.contains { record in
            record.ownerPID == processIdentifier && record.layer == 0 && record.alpha > 0
        }
    }
}

private extension WindowVisibility.Record {
    init?(windowInfo: [String: Any]) {
        guard let ownerPID = (windowInfo[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
              let layer = (windowInfo[kCGWindowLayer as String] as? NSNumber)?.intValue else {
            return nil
        }

        self.init(
            ownerPID: ownerPID,
            layer: layer,
            alpha: (windowInfo[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 0
        )
    }
}
