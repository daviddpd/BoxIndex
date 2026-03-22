//
//  TextRecognitionService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import ImageIO
import UIKit
import Vision

enum TextRecognitionService {
    static func recognizeText(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            return []
        }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = false
        request.recognitionLanguages = [Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = false
        
        let observations = try await request.perform(
            on: cgImage,
            orientation: image.cgImagePropertyOrientation
        )

        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .map(\.trimmed)
            .filter { !$0.isEmpty }
    }
}
