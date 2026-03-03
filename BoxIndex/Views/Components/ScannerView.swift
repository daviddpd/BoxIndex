//
//  ScannerView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import SwiftUI
import VisionKit

enum ScannerPayload {
    case text(String)
    case barcode(String)
}

struct ScannerView: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let onItemRecognized: (ScannerPayload) -> Void

    static var canScan: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator

        DispatchQueue.main.async {
            try? controller.startScanning()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: ScannerView

        init(parent: ScannerView) {
            self.parent = parent
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            forward(items: addedItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            forward(items: updatedItems)
        }

        private func forward(items: [RecognizedItem]) {
            for item in items {
                switch item {
                case .text(let text):
                    parent.onItemRecognized(.text(text.transcript))
                case .barcode(let code):
                    if let payload = code.payloadStringValue {
                        parent.onItemRecognized(.barcode(payload))
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
