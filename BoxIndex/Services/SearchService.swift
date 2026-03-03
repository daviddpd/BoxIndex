//
//  SearchService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

struct SearchMatch {
    let container: Container
    let score: Int
}

enum SearchService {
    static func search(query: String, in containers: [Container], includeArchived: Bool = true) -> [Container] {
        let trimmedQuery = query.trimmed

        guard !trimmedQuery.isEmpty else {
            return includeArchived ? containers : containers.filter { !$0.isArchived }
        }

        let normalizedQuery = normalize(trimmedQuery)
        let condensedQuery = condensed(trimmedQuery)
        let queryTokens = Set(tokens(for: trimmedQuery))
        var matches: [SearchMatch] = []

        for container in containers {
            if !includeArchived && container.isArchived {
                continue
            }

            let bestScore = score(
                container: container,
                normalizedQuery: normalizedQuery,
                condensedQuery: condensedQuery,
                queryTokens: queryTokens
            )

            if bestScore > 0 {
                matches.append(SearchMatch(container: container, score: bestScore))
            }
        }

        matches.sort { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.container.displayTitle.localizedCaseInsensitiveCompare(rhs.container.displayTitle) == .orderedAscending
            }

            return lhs.score > rhs.score
        }

        return matches.map(\.container)
    }

    nonisolated static func normalize(_ value: String) -> String {
        let uppercase = value.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let replaced = uppercase
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " ")

        let cleanedScalars = replaced.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || CharacterSet.whitespaces.contains(scalar) {
                return Character(scalar)
            }

            return " "
        }

        let cleaned = String(cleanedScalars)
        let collapsed = cleaned
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        return collapsed
    }

    nonisolated static func condensed(_ value: String) -> String {
        normalize(value).replacingOccurrences(of: " ", with: "")
    }

    nonisolated static func tokens(for value: String) -> [String] {
        normalize(value)
            .split(separator: " ")
            .map(String.init)
    }

    nonisolated static func parseCommaSeparated(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
    }

    nonisolated static func joinedList(_ values: [String]) -> String {
        values
            .map(\.trimmed)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private static func score(
        container: Container,
        normalizedQuery: String,
        condensedQuery: String,
        queryTokens: Set<String>
    ) -> Int {
        var best = 0

        for value in container.searchableValues {
            let normalizedValue = normalize(value)
            let condensedValue = condensed(value)

            if normalizedValue == normalizedQuery {
                best = max(best, 1_000)
            } else if condensedValue == condensedQuery {
                best = max(best, 960)
            } else if normalizedValue.hasPrefix(normalizedQuery) {
                best = max(best, 820)
            } else if normalizedValue.contains(normalizedQuery) {
                best = max(best, 720)
            } else {
                let matchedTokens = queryTokens.intersection(Set(tokens(for: value))).count
                if matchedTokens > 0 {
                    best = max(best, 500 + (matchedTokens * 40))
                }
            }
        }

        return best
    }
}

extension String {
    nonisolated var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated var nilIfBlank: String? {
        let trimmedValue = trimmed
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
