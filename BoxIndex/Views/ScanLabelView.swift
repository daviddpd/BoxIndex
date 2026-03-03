//
//  ScanLabelView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI
import Vision
import VisionKit

struct ScanLabelView: View {
    @Environment(\.dismiss) private var dismiss

    let containers: [Container]
    let openContainer: (Container) -> Void
    let prefillSearch: (String) -> Void

    @State private var detectedText = ""
    @State private var matchResult: LabelMatchResult?
    @State private var showingCameraCapture = false
    @State private var isProcessingImageOCR = false
    @State private var lastProcessedNormalizedText = ""
    @State private var alreadyMatched = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Point the camera at a printed label like GB-004, Holiday Decor, or Closet Tote A.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Group {
                    if ScannerView.canScan {
                        ScannerView(recognizedDataTypes: [.text()]) { payload in
                            handle(payload)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        )
                    } else {
                        ContentUnavailableView(
                            "Live Text Scanning Unavailable",
                            systemImage: "text.viewfinder",
                            description: Text("Use the photo OCR fallback instead. BoxIndex will read the captured image and try the same deterministic label matching.")
                        )
                    }
                }
                .frame(height: 360)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Detected Text")
                        .font(.headline)

                    Text(detectedText.isEmpty ? "Nothing recognized yet." : detectedText)
                        .font(.body)
                        .foregroundStyle(detectedText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isProcessingImageOCR {
                        ProgressView("Running OCR…")
                            .font(.footnote)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if let matchResult, let primary = matchResult.primary {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best Match")
                            .font(.headline)

                        Button {
                            openAndDismiss(primary.container)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(primary.container.displayTitle)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(primary.container.labelCode)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(primary.reason.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        if matchResult.candidates.count > 1 {
                            Text("Possible Matches")
                                .font(.headline)

                            ForEach(Array(matchResult.candidates.dropFirst().prefix(3).enumerated()), id: \.offset) { _, candidate in
                                Button {
                                    openAndDismiss(candidate.container)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(candidate.container.displayTitle)
                                                .foregroundStyle(.primary)
                                            Text(candidate.reason.title)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(candidate.container.labelCode)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if !detectedText.trimmed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No direct match yet.")
                            .font(.headline)
                        Text("You can use the scanned text to jump into search and narrow it down manually.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                if !detectedText.trimmed.isEmpty {
                    Button {
                        prefillSearch(detectedText)
                    } label: {
                        Label("Use in Search", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Scan Label")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCameraCapture = true
                } label: {
                    Label("Photo OCR", systemImage: "camera")
                }
            }
        }
        .sheet(isPresented: $showingCameraCapture) {
            CameraCaptureView(
                onImagePicked: { image in
                    showingCameraCapture = false
                    Task {
                        await runFallbackOCR(on: image)
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
        guard case .text(let text) = payload else {
            return
        }

        process(recognizedText: text)
    }

    private func process(recognizedText: String) {
        let trimmedText = recognizedText.trimmed
        let normalized = SearchService.normalize(trimmedText)

        guard !trimmedText.isEmpty, normalized != lastProcessedNormalizedText else {
            return
        }

        lastProcessedNormalizedText = normalized
        detectedText = trimmedText

        let result = LabelMatchingService.bestMatch(for: trimmedText, containers: containers)
        matchResult = result

        if result.shouldAutoOpen,
           let container = result.primary?.container,
           !alreadyMatched {
            alreadyMatched = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                openAndDismiss(container)
            }
        }
    }

    private func runFallbackOCR(on image: UIImage) async {
        isProcessingImageOCR = true
        defer { isProcessingImageOCR = false }

        do {
            let recognizedLines = try await TextRecognitionService.recognizeText(in: image)
            let mergedText = LabelMatchingService.combineRecognizedText(recognizedLines)
            process(recognizedText: mergedText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openAndDismiss(_ container: Container) {
        openContainer(container)
    }
}
