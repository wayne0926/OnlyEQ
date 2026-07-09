import Foundation

/// Context passed from device detection into the existing online preset browser.
struct ProfileSuggestion: Equatable {
    var deviceUID: String
    var deviceName: String
    var searchQuery: String
}

enum HeadphoneNameMatcher {
    private static let ignoredWords: Set<String> = [
        "audio", "bluetooth", "headphone", "headphones", "headset", "le",
        "stereo", "wireless",
    ]

    /// Turns names exposed by Core Audio into a useful catalog query. Examples:
    /// “Aaron’s WH-1000XM5 Stereo” → “WH-1000XM5”.
    static func searchQuery(for deviceName: String) -> String {
        var name = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(
            of: #"^[^\s]+[’']s\s+"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        name = name.replacingOccurrences(
            of: #"\s*[\(\[](?:bluetooth|stereo|wireless|audio)[^\)\]]*[\)\]]\s*"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        name = name.replacingOccurrences(of: #"^(?:LE[_\-\s]+)"#, with: "",
                                         options: [.regularExpression, .caseInsensitive])

        let words = name.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let useful = words.filter { !ignoredWords.contains(normalizedWord($0)) }
        return (useful.isEmpty ? words : useful).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Deterministic score used only to choose among catalog results. Model
    /// numbers and exact containment intentionally outweigh general word overlap.
    static func score(query: String, candidate: String) -> Double {
        let queryWords = normalizedWords(query)
        let candidateWords = normalizedWords(candidate)
        guard !queryWords.isEmpty, !candidateWords.isEmpty else { return 0 }

        let queryJoined = queryWords.joined()
        let candidateJoined = candidateWords.joined()
        if queryJoined == candidateJoined { return 1 }
        if candidateJoined.contains(queryJoined) || queryJoined.contains(candidateJoined) { return 0.96 }

        let candidateSet = Set(candidateWords)
        let exactMatches = queryWords.filter(candidateSet.contains)
        let exactRatio = Double(exactMatches.count) / Double(queryWords.count)
        let modelWords = queryWords.filter { $0.contains(where: \.isNumber) }
        let modelRatio = modelWords.isEmpty ? 0 : Double(modelWords.filter(candidateSet.contains).count) / Double(modelWords.count)
        return min(0.95, exactRatio * 0.65 + modelRatio * 0.30)
    }

    private static func normalizedWords(_ value: String) -> [String] {
        value.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !ignoredWords.contains($0) }
    }

    private static func normalizedWord(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
