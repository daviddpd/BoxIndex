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
    @Environment(\.openURL) private var openURL

    let containers: [Container]
    var showsCloseButton = true
    let onMatch: (Container) -> Void

    @State private var cameraAuthorizationState: CameraAuthorizationState = .notDetermined
    @State private var detectedPayload = ""
    @State private var statusMessage = "Point the camera at a BoxIndex QR code."
    @State private var lastProcessedPayload = ""
    @State private var manualPayload = ""
    @State private var showingCameraCapture = false
    @State private var isProcessingImageBarcode = false
    @State private var errorMessage: String?

    private var canUseLiveScanner: Bool {
        cameraAuthorizationState == .authorized && ScannerView.canScan
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Point the camera at a BoxIndex QR code, or paste the payload below.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if canUseLiveScanner {
                        ScannerView(
                            recognizedDataTypes: [.barcode(symbologies: [.qr])],
                            onItemRecognized: { payload in
                                handle(payload)
                            },
                            onStartFailure: { message in
                                statusMessage = "Live scanning couldn't start. \(message)"
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                    } else {
                        fallbackStateCard
                    }
                }
                .frame(height: 320)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Manual Code")
                        .font(.headline)

                    TextField("Paste QR payload or BoxIndex ID", text: $manualPayload)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                        .accessibilityIdentifier("scanqr.manualInput")

                    Button("Open Code") {
                        handlePayloadValue(manualPayload)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manualPayload.trimmed.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

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

                    if isProcessingImageBarcode {
                        ProgressView("Scanning photo…")
                            .font(.footnote)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("Scan QR")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCameraCapture = true
                } label: {
                    Label("Photo QR", systemImage: "camera")
                }
            }
        }
        .task {
            cameraAuthorizationState = await CameraAuthorizationService.requestAccessIfNeeded()
        }
        .sheet(isPresented: $showingCameraCapture) {
            CameraCaptureView(
                onImagePicked: { image in
                    showingCameraCapture = false
                    Task {
                        await runPhotoBarcodeScan(on: image)
                    }
                },
                onCancel: {
                    showingCameraCapture = false
                }
            )
        }
        .alert(
            "Scan Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
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
        handlePayloadValue(normalizedValue)
    }

    private func handlePayloadValue(_ value: String) {
        let normalizedValue = value.trimmed
        guard !normalizedValue.isEmpty else {
            return
        }

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

    private func runPhotoBarcodeScan(on image: UIImage) async {
        isProcessingImageBarcode = true
        defer { isProcessingImageBarcode = false }

        do {
            let payloads = try await QRCodeService.detectPayloads(in: image)

            guard let firstPayload = payloads.first else {
                statusMessage = "No QR code found in that image."
                return
            }

            if let boxIndexPayload = payloads.first(where: { QRCodeService.extractContainerID(from: $0) != nil }) {
                handlePayloadValue(boxIndexPayload)
            } else {
                handlePayloadValue(firstPayload)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var fallbackStateCard: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                fallbackTitle,
                systemImage: fallbackSystemImage,
                description: Text(fallbackDescription)
            )

            if cameraAuthorizationState == .denied || cameraAuthorizationState == .restricted {
                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var fallbackTitle: String {
        switch cameraAuthorizationState {
        case .denied, .restricted:
            return "Camera Access Is Off"
        case .authorized, .unavailable:
            return "Camera Scanning Unavailable"
        case .notDetermined:
            return "Checking Camera Access"
        }
    }

    private var fallbackSystemImage: String {
        switch cameraAuthorizationState {
        case .denied, .restricted:
            return "camera.fill.badge.xmark"
        case .authorized, .unavailable:
            return "camera.metering.unknown"
        case .notDetermined:
            return "camera"
        }
    }

    private var fallbackDescription: String {
        switch cameraAuthorizationState {
        case .denied, .restricted:
            return "Enable camera access in Settings to scan QR codes live. You can still paste a BoxIndex QR payload, UUID, or `boxindex://` link below, or scan one from a photo."
        case .authorized:
            return "Live QR scanning needs supported iPhone hardware. You can still paste a BoxIndex QR payload or container ID directly, or scan one from a photo."
        case .unavailable:
            return "This device does not expose a usable camera. Paste a BoxIndex QR payload or container ID below, or scan one from a photo."
        case .notDetermined:
            return "BoxIndex is checking camera access."
        }
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }
}
