import Foundation

final class DependenciesFinder {

    private let fileManager = FileManager.default
    private let config: Config

    init(config: Config) {
        self.config = config
    }

    private func findAllFilePaths(at url: URL, matching: (URL) -> Bool) -> [URL] {
        guard let projectsEnumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return projectsEnumerator
            .allFiles
            .filter { matching($0) }
    }

    private func findProjectFolderPaths(at url: URL) -> [URL] {
        /// У каждого проекта есть один манифест
        /// Манифест всегда в корне проекта, путь до манифеста - путь до проекта
        return findAllFilePaths(at: url, matching: { $0.path.hasSuffix("Project.swift") })
            .map { $0.deletingLastPathComponent() }
    }

    private func extractAllImports(in text: String) -> [String] {
        do {
            /// Находит:
            /// import ProjectAutomation
            /// @testable import Foundation
            /// //@testable import Foundation
            ///
            /// Пропускает:
            /// return "MAC verification failed during PKCS12 import (wrong password?)"
            /// import struct Foundation.CharacterSet
            /// import Foundation.CharacterSet
            let regex = try NSRegularExpression(pattern: #"import (\w+)$"#, options: [.anchorsMatchLines])
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

            return results.compactMap { match in
                Range(match.range, in: text).map { range in
                    String(text[range])
                }
            }
            .map { importString -> String in
                String(importString.dropFirst("import ".count))
            }
        } catch {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    private func findTargetDependencies(at url: URL) async -> TargetDependencies {
        TargetDependencies(
            targetName: url.lastPathComponent,
            dependencies: await findAllUniqueImports(at: url)
        )
    }

    private func findAppTargetDependencies(at url: URL) async -> TargetDependencies {
        TargetDependencies(
            targetName: "",
            dependencies: await findAllUniqueImports(at: url.appendingPathComponent("Main/Sources"))
                + findAllUniqueImports(at: url.appendingPathComponent("HH/Sources"))
                + findAllUniqueImports(at: url.appendingPathComponent("JTB/Sources"))
                + findAllUniqueImports(at: url.appendingPathComponent("ZP/Sources"))
        )
    }

    private func findAllUniqueImports(at url: URL) async -> [String] {
        await Task.detached {
            self.findAllFilePaths(at: url, matching: { $0.pathExtension == "swift" })
                .compactMap { filePath -> [String] in
                    let fileContent = try? String(contentsOfFile: filePath.path)
                    return self.extractAllImports(in: fileContent ?? "")
                }
                .flatMap { $0 }
                .onlyUnique
                .filter { !self.config.excludedImports.contains($0) }
                .sorted()
        }.value
    }

    private func makeFeatureType(appURL url: URL) throws -> FeatureType {
        guard let type = FeatureType(rawValue: url.lastPathComponent) else {
            throw GenerationError.unresolvedFeatureType(url: url)
        }

        return type
    }

    private func findAppDependencies(at url: URL) async throws -> ProjectDependencies {
        ProjectDependencies(
            projectName: "App\(url.lastPathComponent)",
            featureType: try makeFeatureType(appURL: url),
            targetDependencies: [
                await findAppTargetDependencies(at: url),
                await findTargetDependencies(at: url.appendingPathComponent("UnitTests")),
                await findTargetDependencies(at: url.appendingPathComponent("UITests")),
                await findTargetDependencies(at: url.appendingPathComponent("Extensions/Widget")),
                await findTargetDependencies(at: url.appendingPathComponent("Extensions/TodayWidget"))
            ]
        )
    }

    private func makeFeatureType(featureURL url: URL) throws -> FeatureType {
        guard let featuresPathIndex = url.pathComponents.firstIndex(of: "Features"),
              let type = FeatureType(rawValue: url.pathComponents[featuresPathIndex + 1]) else {
            throw GenerationError.unresolvedFeatureType(url: url)
        }

        return type
    }

    private func findFeatureDependencies(at url: URL) async throws -> ProjectDependencies {
        ProjectDependencies(
            projectName: url.lastPathComponent,
            featureType: try makeFeatureType(featureURL: url),
            targetDependencies: [
                await findTargetDependencies(at: url.appendingPathComponent("Sources")),
                await findTargetDependencies(at: url.appendingPathComponent("Core")),
                await findTargetDependencies(at: url.appendingPathComponent("Tests")),
                await findTargetDependencies(at: url.appendingPathComponent("Testing"))
            ]
        )
    }

    func findDependencies() async throws -> [ProjectDependencies] {
        let workspace = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        let appFolders = findProjectFolderPaths(at: workspace.appendingPathComponent("Apps"))
        let featureFolders = findProjectFolderPaths(at: workspace.appendingPathComponent("Features"))

        let appDependencies = try await appFolders.concurrentMap(findAppDependencies(at:))
        let featureDependencies = try await featureFolders.concurrentMap(findFeatureDependencies(at:))

        return appDependencies
               + featureDependencies
    }
}
