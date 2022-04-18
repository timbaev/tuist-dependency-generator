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

    private func findTargetDependencies(at url: URL) -> TargetDependencies {
        TargetDependencies(
            targetName: url.lastPathComponent,
            dependencies: findAllUniqueImports(at: url)
        )
    }

    private func findAppTargetDependencies(at url: URL) -> TargetDependencies {
        TargetDependencies(
            targetName: "",
            dependencies: findAllUniqueImports(at: url.appendingPathComponent("Main/Sources"))
                + findAllUniqueImports(at: url.appendingPathComponent("HH/Sources"))
                + findAllUniqueImports(at: url.appendingPathComponent("JTB/Sources"))
        )
    }

    private func findAllUniqueImports(at url: URL) -> [String] {
        return findAllFilePaths(at: url, matching: { $0.pathExtension == "swift" })
            .compactMap { filePath -> [String] in
                let fileContent = try? String(contentsOfFile: filePath.path)
                return extractAllImports(in: fileContent ?? "")
            }
            .flatMap { $0 }
            .onlyUnique
            .filter { !config.excludedImports.contains($0) }
            .sorted()
    }

    private func findAppDependencies(at url: URL) -> ProjectDependencies {
        ProjectDependencies(
            projectName: url.lastPathComponent,
            targetDependencies: [
                findAppTargetDependencies(at: url),
                findTargetDependencies(at: url.appendingPathComponent("UnitTests")),
                findTargetDependencies(at: url.appendingPathComponent("UITests")),
                findTargetDependencies(at: url.appendingPathComponent("Extensions/Widget")),
                findTargetDependencies(at: url.appendingPathComponent("Extensions/TodayWidget"))
            ]
        )
    }

    private func findFeatureDependencies(at url: URL) -> ProjectDependencies {
        ProjectDependencies(
            projectName: url.lastPathComponent,
            targetDependencies: [
                findTargetDependencies(at: url.appendingPathComponent("Sources")),
                findTargetDependencies(at: url.appendingPathComponent("Core")),
                findTargetDependencies(at: url.appendingPathComponent("Example")),
                findTargetDependencies(at: url.appendingPathComponent("Tests")),
                findTargetDependencies(at: url.appendingPathComponent("Testing"))
            ]
        )
    }

    func findDependencies() -> [ProjectDependencies] {
        let workspace = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        let appFolders = findProjectFolderPaths(at: workspace.appendingPathComponent("Apps"))
        let featureFolders = findProjectFolderPaths(at: workspace.appendingPathComponent("Features"))

        let appDependencies = appFolders.map(findAppDependencies(at:))
        let featureDependencies = featureFolders.map(findFeatureDependencies(at:))

        return appDependencies
               + featureDependencies
    }
}
