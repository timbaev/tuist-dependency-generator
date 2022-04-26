import Foundation

enum GenerationError: Error, CustomStringConvertible {

    case unresolvedFeatureType(url: URL)

    var description: String {
        switch self {
        case let .unresolvedFeatureType(url):
            return "Can't resolve feature type from url: \(url.absoluteString)"
        }
    }
}
