extension String {

    func fillFileTemplate(
        _ template: String = "// swiftlint:disable all\n\n#content#\n"
    ) -> String {
        template
            .replacingOccurrences(of: "#content#", with: self)
    }
}
