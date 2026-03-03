//
//  QRCodeService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum QRCodeService {
    static let prefix = "BOXINDEX:"

    private static let context = CIContext()

    static func image(for container: Container, size: CGFloat = 220) -> UIImage? {
        image(for: container.qrPayload, size: size)
    }

    static func image(for payload: String, size: CGFloat = 220) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scale = max(size / outputImage.extent.width, size / outputImage.extent.height)
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    static func extractContainerID(from payload: String) -> UUID? {
        let trimmedPayload = payload.trimmed

        if let uuid = UUID(uuidString: trimmedPayload) {
            return uuid
        }

        let uppercased = trimmedPayload.uppercased()
        if uppercased.hasPrefix(prefix) {
            let idString = String(trimmedPayload.dropFirst(prefix.count))
            return UUID(uuidString: idString)
        }

        if let components = URLComponents(string: trimmedPayload),
           components.scheme?.lowercased() == "boxindex" {
            let idString = components.path.replacingOccurrences(of: "/", with: "")
            return UUID(uuidString: idString)
        }

        return nil
    }
}
