//
//  CameraAuthorizationService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import AVFoundation

enum CameraAuthorizationState: Equatable {
    case unavailable
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
enum CameraAuthorizationService {
    static func currentState() -> CameraAuthorizationState {
        guard AVCaptureDevice.default(for: .video) != nil else {
            return .unavailable
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    static func requestAccessIfNeeded() async -> CameraAuthorizationState {
        let state = currentState()

        guard state == .notDetermined else {
            return state
        }

        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }

        return granted ? .authorized : .denied
    }
}
