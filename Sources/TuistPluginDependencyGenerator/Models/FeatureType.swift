enum FeatureType: String {

    case applicant = "Applicant"
    case employer = "Employer"
    case shared = "Shared"

    init?(rawValue: String) {
        switch rawValue {
        case "Applicant":
            self = .applicant

        case "Employer", "HRMobile":
            self = .employer

        case "Shared":
            self = .shared

        default:
            return nil
        }
    }
}
