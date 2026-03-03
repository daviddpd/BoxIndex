//
//  ContainerItemRowView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI

struct ContainerItemRowView: View {
    let item: ContainerItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.name.trimmed.isEmpty ? "Untitled Item" : item.name)
                    .font(.headline)

                Spacer()

                if let quantityText = item.quantityText {
                    Text("x\(quantityText)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let tagSummary = item.tagSummary {
                Text(tagSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = item.notes?.trimmed, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
