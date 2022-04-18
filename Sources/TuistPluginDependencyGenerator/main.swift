import Foundation

let startDate = Date()
let config = Config()

let dependenciesFinder = DependenciesFinder(config: config)
let dependencyGenerator = DependencyGenerator(config: config)

if FileManager.default.fileExists(atPath: config.generationPath) {
    let url = URL(fileURLWithPath: config.generationPath)
    try FileManager.default.removeItem(at: url)
}

try dependenciesFinder
    .findDependencies()
    .forEach { projectDependencies in
        try dependencyGenerator.generate(projectDependencies: projectDependencies)
    }

let endDate = Date()

print("Execution time: \(String(format: "%.3f", endDate.timeIntervalSince(startDate)))")
