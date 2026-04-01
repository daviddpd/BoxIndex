//
//  ContainerIconPickerView.swift
//  BoxIndex
//
//  Created by Codex on 3/31/26.
//

import SwiftUI

struct ContainerIconPickerView: View {
    @Binding var selection: String

    private let columns = [
        GridItem(.adaptive(minimum: 82, maximum: 120), spacing: 12),
    ]

    private var selectedIcon: ContainerIcon? {
        ContainerIcon(rawValue: selection)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Section {
                    Button {
                        selection = ""
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "nosign")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("No Custom Icon")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Use the default box icon on labels and list rows.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: selection.isEmpty ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection.isEmpty ? Color.accentColor : .secondary)
                                .font(.title3)
                        }
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if let selectedIcon {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Selection")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ContainerIconBadgeView(icon: selectedIcon, size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedIcon.title)
                                    .font(.headline)
                                Text(selectedIcon.category.title)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                ForEach(ContainerIcon.groupedIcons, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.category.title)
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(group.icons) { icon in
                                Button {
                                    selection = icon.rawValue
                                } label: {
                                    SelectableIconTile(
                                        icon: icon,
                                        isSelected: icon.rawValue == selection
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(icon.title)
                                .accessibilityValue(icon.rawValue == selection ? "Selected" : "Not selected")
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Container Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContainerIconBadgeView: View {
    let icon: ContainerIcon
    var size: CGFloat = 40
    var accentColor: Color? = nil

    private var resolvedAccentColor: Color {
        accentColor ?? icon.color
    }

    var body: some View {
        Image(systemName: icon.resolvedSymbolName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(resolvedAccentColor)
            .frame(width: size, height: size)
            .background(resolvedAccentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

private struct SelectableIconTile: View {
    let icon: ContainerIcon
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ContainerIconBadgeView(icon: icon, size: 56)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary.opacity(0.45))
                    .background(Color(.systemBackground), in: Circle())
                    .offset(x: 4, y: -4)
            }

            Text(icon.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            isSelected
                ? icon.color.opacity(0.16)
                : Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSelected ? icon.color.opacity(0.5) : Color.clear,
                    lineWidth: 1.2
                )
        }
    }
}
