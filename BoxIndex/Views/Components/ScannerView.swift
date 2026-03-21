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
    var onStartFailure: ((String) -> Void)? = nil

    static var canScan: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> ScannerContainerViewController {
        let scannerController = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scannerController.delegate = context.coordinator

        return ScannerContainerViewController(
            scannerController: scannerController,
            onStartFailure: onStartFailure
        )
    }

    func updateUIViewController(_ uiViewController: ScannerContainerViewController, context: Context) {
    }

    static func dismantleUIViewController(_ uiViewController: ScannerContainerViewController, coordinator: Coordinator) {
        uiViewController.stopScanningIfNeeded()
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

final class ScannerContainerViewController: UIViewController {
    private let scannerController: DataScannerViewController
    private let onStartFailure: ((String) -> Void)?
    private var hasStartedScanning = false

    init(
        scannerController: DataScannerViewController,
        onStartFailure: ((String) -> Void)?
    ) {
        self.scannerController = scannerController
        self.onStartFailure = onStartFailure
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(scannerController)
        view.addSubview(scannerController.view)
        scannerController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scannerController.view.topAnchor.constraint(equalTo: view.topAnchor),
            scannerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scannerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scannerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        scannerController.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasStartedScanning else {
            return
        }

        do {
            try scannerController.startScanning()
            hasStartedScanning = true
        } catch {
            onStartFailure?(error.localizedDescription)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanningIfNeeded()
    }

    func stopScanningIfNeeded() {
        guard hasStartedScanning else {
            return
        }

        scannerController.stopScanning()
        hasStartedScanning = false
    }
}
