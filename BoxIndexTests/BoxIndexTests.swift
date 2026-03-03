//
//  BoxIndexTests.swift
//  BoxIndexTests
//
//  Created by David P. Discher on 3/2/26.
//

import Testing
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

}
