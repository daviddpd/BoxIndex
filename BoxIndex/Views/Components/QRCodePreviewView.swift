//
//  QRCodePreviewView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI

struct QRCodePreviewView: View {
    let container: Container

    var body: some View {
        VStack(spacing: 12) {
            if let image = QRCodeService.image(for: container) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .padding(18)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Image(systemName: "qrcode")
                    .font(.system(size: 68))
                    .foregroundStyle(.secondary)
            }

            Text(container.labelCode)
                .font(.headline)

            Text(container.qrPayload)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
