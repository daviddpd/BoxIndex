//
//  ContainerRowView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI

struct ContainerRowView: View {
    let container: Container

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ContainerColorTag.color(for: container.colorTag) ?? Color.secondary.opacity(0.25))
                .frame(width: 10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(container.displayTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if container.isArchived {
                        Text("Archived")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.secondary.opacity(0.16), in: Capsule())
                    }
                }

                Text(container.labelCode)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(container.locationDisplay, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Label("\(container.items.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let aliasSummary = container.aliasSummary {
                    Text(aliasSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let image = PhotoStorageService.image(for: container.photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 58, height: 58)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
    }
}
