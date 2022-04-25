import Foundation

@main
enum TuistDependencyGenerator {

    static func main() async throws {
        let startDate = Date()
        let config = Config()

        let dependenciesFinder = DependenciesFinder(config: config)
        let dependencyGenerator = DependencyGenerator(config: config)

        if FileManager.default.fileExists(atPath: config.generationPath) {
            let url = URL(fileURLWithPath: config.generationPath)
            try FileManager.default.removeItem(at: url)
        }

        let dependencies = try await dependenciesFinder.findDependencies()
        try await dependencies.concurrentForEach { try await dependencyGenerator.generate(projectDependencies: $0) }

        let endDate = Date()

        print("Execution time: \(String(format: "%.3f", endDate.timeIntervalSince(startDate)))")
    }
}
