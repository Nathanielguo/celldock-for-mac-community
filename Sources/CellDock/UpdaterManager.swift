import Foundation

enum CommunityBuildInfo {
    static var currentVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
            as? String ?? "—"
        return L10n.tr("版本 %@（构建 %@）", version, build)
    }

}
