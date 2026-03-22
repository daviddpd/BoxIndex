//
//  BoxIndexTests.swift
//  BoxIndexTests
//
//  Created by David P. Discher on 3/2/26.
//

import Foundation
import Testing
import UIKit
@testable import BoxIndex

struct BoxIndexTests {

    @Test
    func labelNormalizationTreatsCommonVariantsAsEquivalent() {
        #expect(SearchService.condensed("GB-004") == SearchService.condensed("GB 004"))
        #expect(SearchService.condensed("GB-004") == SearchService.condensed("GB004"))
    }

    @Test
    func labelMatchingPrefersExactLabelCode() {
        let target = Container(name: "Garage Bin 04", labelCode: "GB-004", location: "Garage", aliases: ["Bin 4"])
        let other = Container(name: "Garage Bin 05", labelCode: "GB-005", location: "Garage")

        let result = LabelMatchingService.bestMatch(for: "gb 004", containers: [other, target])

        #expect(result.primary?.container.id == target.id)
        #expect(result.primary?.reason == .exactLabelCode)
        #expect(result.shouldAutoOpen)
    }

    @Test
    func importConflictResolutionKeepsNewestRecord() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)

        #expect(
            ImportConflictResolution.keepNewestRecord.shouldApply(
                importedUpdatedAt: newer,
                existingUpdatedAt: older
            )
        )
        #expect(
            !ImportConflictResolution.keepNewestRecord.shouldApply(
                importedUpdatedAt: older,
                existingUpdatedAt: newer
            )
        )
    }

    @Test
    func migrationPlanExposesCurrentSchema() {
        #expect(BoxIndexMigrationPlan.schemas.count == 1)
        #expect(BoxIndexSchemaV1.models.count == 3)
    }

    @Test
    func detectPayloadsReadsGeneratedQRCodeImage() async throws {
        let payload = "BOXINDEX:550E8400-E29B-41D4-A716-446655440000"
        let image = try #require(QRCodeService.image(for: payload, size: 400))

        let detectedPayloads = try await QRCodeService.detectPayloads(in: image)

        #expect(detectedPayloads.contains(payload))
    }

    @Test
    @MainActor
    func qrLabelSheetPDFStartsWithPDFHeader() throws {
        let service = QRLabelOutputService()
        let container = Container(name: "Garage Bin 04", labelCode: "GB-004", location: "Garage", colorTag: "blue")

        let pdfData = try service.sheetPDFData(for: [container], options: QRLabelOutputOptions())

        #expect(String(decoding: pdfData.prefix(4), as: UTF8.self) == "%PDF")
    }

    @Test
    @MainActor
    func qrLabelExportPackageContainsManifestSheetAndPNG() throws {
        let service = QRLabelOutputService()
        let container = Container(name: "Holiday Decor", labelCode: "HD-001", location: "Closet", colorTag: "coral")

        let package = try service.buildExportPackage(from: [container], options: QRLabelOutputOptions())
        defer {
            try? FileManager.default.removeItem(at: package.directoryURL)
        }

        let manifestURL = package.directoryURL.appendingPathComponent("qr-label-export.json")
        let sheetURL = package.directoryURL.appendingPathComponent("sheet-letter-twoByTwo.pdf")
        let imagesURL = package.directoryURL.appendingPathComponent("individual", isDirectory: true)
        let imageFiles = try FileManager.default.contentsOfDirectory(at: imagesURL, includingPropertiesForKeys: nil)

        #expect(FileManager.default.fileExists(atPath: manifestURL.path))
        #expect(FileManager.default.fileExists(atPath: sheetURL.path))
        #expect(imageFiles.count == 1)
        #expect(imageFiles.first?.pathExtension.lowercased() == "png")
    }

}
