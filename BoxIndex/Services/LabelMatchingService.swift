//
//  LabelMatchingService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation

enum LabelMatchReason: String {
    case exactLabelCode
    case exactName
    case exactAlias
    case contains
    case token

    var title: String {
        switch self {
        case .exactLabelCode:
            return "Label code"
        case .exactName:
            return "Name"
        case .exactAlias:
            return "Alias"
        case .contains:
            return "Partial match"
        case .token:
            return "Keyword match"
        }
    }
}

struct LabelMatchCandidate {
    let container: Container
    let reason: LabelMatchReason
    let score: Int
}

struct LabelMatchResult {
    let inputText: String
    let normalizedInput: String
    let candidates: [LabelMatchCandidate]

    var primary: LabelMatchCandidate? { candidates.first }

    var shouldAutoOpen: Bool {
        guard let primary else {
            return false
        }

        if primary.score >= 900 {
            return true
        }

        if candidates.count == 1, primary.score >= 720 {
            return true
        }

        guard candidates.count > 1 else {
            return false
        }

        return primary.score >= 780 && (primary.score - candidates[1].score) >= 150
    }
}

enum LabelMatchingService {
    static func bestMatch(for scannedText: String, containers: [Container]) -> LabelMatchResult {
        let normalizedInput = SearchService.normalize(scannedText)
        let condensedInput = SearchService.condensed(scannedText)
        let queryTokens = Set(SearchService.tokens(for: scannedText))

        let candidates = containers
            .filter { !$0.isArchived }
            .compactMap { container in
                score(container: container, normalizedInput: normalizedInput, condensedInput: condensedInput, queryTokens: queryTokens)
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.container.displayTitle.localizedCaseInsensitiveCompare($1.container.displayTitle) == .orderedAscending
                }

                return $0.score > $1.score
            }

        return LabelMatchResult(
            inputText: scannedText,
            normalizedInput: normalizedInput,
            candidates: Array(candidates.prefix(4))
        )
    }

    static func combineRecognizedText(_ lines: [String]) -> String {
        let cleaned = lines
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        guard !cleaned.isEmpty else {
            return ""
        }

        if let bestLabelCode = cleaned.first(where: { SearchService.condensed($0).count >= 3 }) {
            return bestLabelCode
        }

        return cleaned.joined(separator: " ")
    }

    private static func score(
        container: Container,
        normalizedInput: String,
        condensedInput: String,
        queryTokens: Set<String>
    ) -> LabelMatchCandidate? {
        guard !normalizedInput.isEmpty else {
            return nil
        }

        let normalizedLabelCode = SearchService.normalize(container.labelCode)
        let normalizedName = SearchService.normalize(container.name)
        let aliasPairs = container.aliases.map { alias in
            (raw: alias, normalized: SearchService.normalize(alias), condensed: SearchService.condensed(alias))
        }

        if normalizedLabelCode == normalizedInput || SearchService.condensed(container.labelCode) == condensedInput {
            return LabelMatchCandidate(container: container, reason: .exactLabelCode, score: 1_000)
        }

        if normalizedName == normalizedInput || SearchService.condensed(container.name) == condensedInput {
            return LabelMatchCandidate(container: container, reason: .exactName, score: 940)
        }

        if aliasPairs.contains(where: { $0.normalized == normalizedInput || $0.condensed == condensedInput }) {
            return LabelMatchCandidate(container: container, reason: .exactAlias, score: 900)
        }

        let searchable = [
            container.name,
            container.labelCode,
            container.location,
            container.subLocation,
            container.notes,
        ]
        .compactMap { $0 }
        + container.aliases
        + container.items.map(\.name)

        for value in searchable {
            let normalizedValue = SearchService.normalize(value)
            if normalizedValue.contains(normalizedInput) {
                return LabelMatchCandidate(container: container, reason: .contains, score: 760)
            }
        }

        let matchedTokens = queryTokens.intersection(Set(container.searchableValues.flatMap(SearchService.tokens(for:)))).count
        guard matchedTokens > 0 else {
            return nil
        }

        return LabelMatchCandidate(
            container: container,
            reason: .token,
            score: 520 + (matchedTokens * 45)
        )
    }
}
