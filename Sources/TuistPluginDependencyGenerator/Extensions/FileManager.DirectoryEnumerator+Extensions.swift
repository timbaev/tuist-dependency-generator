import Foundation

extension FileManager.DirectoryEnumerator {

    var allFiles: [URL] {
        (allObjects as? [URL]) ?? []
    }
}
