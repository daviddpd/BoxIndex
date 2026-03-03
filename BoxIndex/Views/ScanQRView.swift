//
//  ScanQRView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI
import Vision
import VisionKit

struct ScanQRView: View {
    @Environment(\.dismiss) private var dismiss

    let containers: [Container]
    let onMatch: (Container) -> Void

    @State private var detectedPayload = ""
    @State private var statusMessage = "Point the camera at a BoxIndex QR code."
    @State private var lastProcessedPayload = ""

    var body: some View {
        VStack(spacing: 18) {
            Group {
                if ScannerView.canScan {
                    ScannerView(recognizedDataTypes: [.barcode(symbologies: [.qr])]) { payload in
                        handle(payload)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                } else {
                    ContentUnavailableView(
                        "Camera Scanning Unavailable",
                        systemImage: "camera.metering.unknown",
                        description: Text("Live QR scanning needs a supported device. Use a recent iPhone or test on hardware.")
                    )
                }
            }
            .frame(maxHeight: 420)

            VStack(alignment: .leading, spacing: 10) {
                Text("Detected")
                    .font(.headline)

                Text(detectedPayload.isEmpty ? "No QR code detected yet." : detectedPayload)
                    .font(.body.monospaced())
                    .foregroundStyle(detectedPayload.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Spacer()
        }
        .padding()
        .navigationTitle("Scan QR")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }

    private func handle(_ payload: ScannerPayload) {
        guard case .barcode(let value) = payload else {
            return
        }

        let normalizedValue = value.trimmed
        guard !normalizedValue.isEmpty, normalizedValue != lastProcessedPayload else {
            return
        }

        lastProcessedPayload = normalizedValue
        detectedPayload = normalizedValue

        guard let containerID = QRCodeService.extractContainerID(from: normalizedValue) else {
            statusMessage = "This QR code is not a BoxIndex container code."
            return
        }

        guard let container = containers.first(where: { $0.id == containerID }) else {
            statusMessage = "That QR code does not match a saved container on this iPhone."
            return
        }

        statusMessage = "Opening \(container.displayTitle)…"
        onMatch(container)
    }
}
