extension Array where Element: Hashable {

    var onlyUnique: Self {
        Array(Set(self))
    }
}
