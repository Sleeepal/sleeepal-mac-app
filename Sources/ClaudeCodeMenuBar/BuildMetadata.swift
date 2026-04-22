import Foundation

struct BuildMetadata {
    let version: String
    let buildNumber: String
    let packagedAt: String

    static let current: BuildMetadata = {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"

        let packagedAt: String
        if
            let url = bundle.url(forResource: "BuildInfo", withExtension: "plist"),
            let info = NSDictionary(contentsOf: url),
            let value = info["PackagedAt"] as? String,
            !value.isEmpty
        {
            packagedAt = value
        } else {
            packagedAt = "development build"
        }

        return BuildMetadata(version: version, buildNumber: buildNumber, packagedAt: packagedAt)
    }()

    var stamp: String {
        "v\(version) (\(buildNumber)) · 打包于 \(packagedAt)"
    }
}
