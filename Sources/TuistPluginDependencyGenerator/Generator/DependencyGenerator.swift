import Foundation

final class DependencyGenerator {

    private let fileManager = FileManager.default
    private let config: Config

    init(config: Config) {
        self.config = config
    }

    func generate(projectDependencies: ProjectDependencies) throws {
        let url = URL(fileURLWithPath: config.generationPath)

        if !fileManager.fileExists(atPath: config.generationPath) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }

        let fileURL = url.appendingPathComponent("\(projectDependencies.projectName)Dependencies.generated.swift")

        let dependenciesString = projectDependencies.targetDependencies
            .map { $0.dependencies.fillTemplate(name: projectDependencies.projectName + $0.targetName) }
            .joined(separator: "\n\n")
            .fillFileTemplate()

        try dependenciesString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
