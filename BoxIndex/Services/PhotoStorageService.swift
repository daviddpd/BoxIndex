//
//  PhotoStorageService.swift
//  BoxIndex
//
//  Created by Codex on 3/2/26.
//

import Foundation
import UIKit

enum PhotoStorageService {
    private static let directoryName = "ContainerPhotos"

    static func image(for relativePath: String?) -> UIImage? {
        guard let relativePath, let url = url(for: relativePath) else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return UIImage(data: data)
    }

    static func url(for relativePath: String) -> URL? {
        do {
            return try photosDirectory().appendingPathComponent(relativePath)
        } catch {
            return nil
        }
    }

    static func saveJPEGImage(_ image: UIImage, replacing existingPath: String? = nil) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let directory = try photosDirectory()
        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = directory.appendingPathComponent(fileName)

        try data.write(to: destinationURL, options: [.atomic])

        if let existingPath {
            deletePhoto(at: existingPath)
        }

        return fileName
    }

    static func importPhoto(from sourceURL: URL, replacing existingPath: String? = nil) throws -> String {
        let directory = try photosDirectory()
        let fileName = "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        let destinationURL = directory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        if let existingPath {
            deletePhoto(at: existingPath)
        }

        return fileName
    }

    static func deletePhoto(at relativePath: String?) {
        guard let relativePath, let fileURL = url(for: relativePath) else {
            return
        }

        try? FileManager.default.removeItem(at: fileURL)
    }

    private static func photosDirectory() throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }
}
