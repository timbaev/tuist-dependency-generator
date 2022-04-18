extension Array where Element: Hashable {

    var onlyUnique: Self {
        Array(Set(self))
    }
}

extension Array where Element == String {

    func fillTemplate(
        _ template: String = "public let #name#Dependencies: [Dependency] = [\n#deps#\n]",
        name: String
    ) -> String {
        template
            .replacingOccurrences(of: "#name#", with: name)
            .replacingOccurrences(of: "#deps#", with: self.map { "    .\($0)" }.joined(separator: ",\n"))
    }
}
