import Foundation

// Makes "Ya Kun", "yakun" and "YA-KUN" all look the same, so searches are forgiving.
enum SearchText {

    static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    // 0 = name starts with the query, 1 = name contains it, 2 = only the address contains it, nil = no match.
    static func rank(query: String, name: String, address: String) -> Int? {
        let q = normalized(query)
        guard !q.isEmpty else { return nil }
        let n = normalized(name)
        if n.hasPrefix(q) { return 0 }
        if n.contains(q) { return 1 }
        if normalized(address).contains(q) { return 2 }
        return nil
    }
}
