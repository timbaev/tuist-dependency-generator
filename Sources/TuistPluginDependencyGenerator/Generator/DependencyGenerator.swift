import Foundation

final class DependencyGenerator {

    private let fileManager = FileManager.default
    private let config: Config

    init(config: Config) {
        self.config = config
    }

    private func makeDependenciesContent(
        projectName: String,
        targetName: String,
        featureType: String,
        dependencies: [String]
    ) -> String {
        let dependencyContent = dependencies
            .map { "    DependencyList.\($0)" }
            .joined(separator: ",\n")

        return """
            public let \(projectName)\(targetName)Dependencies = \(featureType)Dependencies(
            \(dependencyContent)
            ).dependencies
            """
    }

    func generate(projectDependencies: ProjectDependencies) async throws {
        try await Task.detached {
            let url = URL(fileURLWithPath: self.config.generationPath)

            if !self.fileManager.fileExists(atPath: self.config.generationPath) {
                try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }

            let fileURL = url.appendingPathComponent("\(projectDependencies.projectName)Dependencies.generated.swift")

            let dependenciesString = projectDependencies.targetDependencies
                .map {
                    self.makeDependenciesContent(
                        projectName: projectDependencies.projectName,
                        targetName: $0.targetName,
                        featureType: projectDependencies.featureType.rawValue,
                        dependencies: $0.dependencies
                    )
                }
                .joined(separator: "\n\n")
                .fillFileTemplate()

            try dependenciesString.write(to: fileURL, atomically: true, encoding: .utf8)
        }.value
    }
}
