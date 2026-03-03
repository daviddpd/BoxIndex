//
//  CameraCaptureView.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void
    var prefersCamera = true

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.allowsEditing = false
        controller.sourceType = preferredSourceType()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            } else {
                parent.onCancel()
            }
        }
    }

    private func preferredSourceType() -> UIImagePickerController.SourceType {
        let videoAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        let canUseCamera = prefersCamera
            && UIImagePickerController.isSourceTypeAvailable(.camera)
            && videoAuthorization != .denied
            && videoAuthorization != .restricted

        if canUseCamera {
            return .camera
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            return .photoLibrary
        }

        return .savedPhotosAlbum
    }
}
