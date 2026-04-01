//
//  ContainerIcon.swift
//  BoxIndex
//
//  Created by Codex on 3/31/26.
//

import SwiftUI
import UIKit

enum ContainerIconCategory: String, CaseIterable, Identifiable {
    case storage
    case seasonal
    case family
    case creative
    case tools
    case home
    case outdoor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .storage:
            return "Storage"
        case .seasonal:
            return "Seasonal & Party"
        case .family:
            return "Family & Fun"
        case .creative:
            return "Creative & Office"
        case .tools:
            return "Tools & Tech"
        case .home:
            return "Home & Essentials"
        case .outdoor:
            return "Outdoor & Travel"
        }
    }
}

enum ContainerIcon: String, CaseIterable, Identifiable {
    case shippingBox
    case archiveBox
    case trayStack
    case folder
    case bag
    case suitcase
    case backpack
    case basket

    case tree	
    case snowflake
    case leaf
    case sun
    case moonStars
    case heart
    case gift
    case party

    case teddyBear
    case puzzle
    case gameController
    case book
    case music
    case camera
    case soccerBall
    case bicycle

    case paintPalette
    case paintBrush
    case scissors
    case pencil
    case ruler
    case paperclip
    case document
    case tag

    case hammer
    case wrenchAndScrewdriver
    case screwdriver
    case powerPlug
    case cable
    case battery
    case printer
    case laptop

    case house
    case cup
    case utensils
    case shirt
    case bed
    case pawprint
    case medicalCase
    case bandage

    case tent
    case car
    case walking
    case map
    case umbrella
    case flashlight
    case fan
    case flame

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shippingBox:
            return "Shipping Box"
        case .archiveBox:
            return "Archive Box"
        case .trayStack:
            return "Tray Stack"
        case .folder:
            return "Folder"
        case .bag:
            return "Bag"
        case .suitcase:
            return "Suitcase"
        case .backpack:
            return "Backpack"
        case .basket:
            return "Basket"
        case .tree:
            return "Holiday Tree"
        case .snowflake:
            return "Snowflake"
        case .leaf:
            return "Leaf"
        case .sun:
            return "Sun"
        case .moonStars:
            return "Moon & Stars"
        case .heart:
            return "Heart"
        case .gift:
            return "Gift"
        case .party:
            return "Party"
        case .teddyBear:
            return "Teddy Bear"
        case .puzzle:
            return "Puzzle"
        case .gameController:
            return "Game Controller"
        case .book:
            return "Book"
        case .music:
            return "Music"
        case .camera:
            return "Camera"
        case .soccerBall:
            return "Soccer Ball"
        case .bicycle:
            return "Bicycle"
        case .paintPalette:
            return "Paint Palette"
        case .paintBrush:
            return "Paint Brush"
        case .scissors:
            return "Scissors"
        case .pencil:
            return "Pencil"
        case .ruler:
            return "Ruler"
        case .paperclip:
            return "Paperclip"
        case .document:
            return "Document"
        case .tag:
            return "Tag"
        case .hammer:
            return "Hammer"
        case .wrenchAndScrewdriver:
            return "Wrench & Screwdriver"
        case .screwdriver:
            return "Screwdriver"
        case .powerPlug:
            return "Power Plug"
        case .cable:
            return "Cable"
        case .battery:
            return "Battery"
        case .printer:
            return "Printer"
        case .laptop:
            return "Laptop"
        case .house:
            return "Household"
        case .cup:
            return "Cup"
        case .utensils:
            return "Kitchen"
        case .shirt:
            return "Clothing"
        case .bed:
            return "Linens"
        case .pawprint:
            return "Pet"
        case .medicalCase:
            return "Medical"
        case .bandage:
            return "First Aid"
        case .tent:
            return "Camping"
        case .car:
            return "Car"
        case .walking:
            return "Walking"
        case .map:
            return "Travel"
        case .umbrella:
            return "Rain Gear"
        case .flashlight:
            return "Flashlight"
        case .fan:
            return "Cooling"
        case .flame:
            return "Heat"
        }
    }

    var symbolName: String {
        switch self {
        case .shippingBox:
            return "shippingbox.fill"
        case .archiveBox:
            return "archivebox.fill"
        case .trayStack:
            return "tray.2.fill"
        case .folder:
            return "folder.fill"
        case .bag:
            return "bag.fill"
        case .suitcase:
            return "suitcase.fill"
        case .backpack:
            return "backpack.fill"
        case .basket:
            return "basket.fill"
        case .tree:
            return "tree.fill"
        case .snowflake:
            return "snowflake"
        case .leaf:
            return "leaf.fill"
        case .sun:
            return "sun.max.fill"
        case .moonStars:
            return "moon.stars.fill"
        case .heart:
            return "heart.fill"
        case .gift:
            return "gift.fill"
        case .party:
            return "party.popper.fill"
        case .teddyBear:
            return "teddybear.fill"
        case .puzzle:
            return "puzzlepiece.fill"
        case .gameController:
            return "gamecontroller.fill"
        case .book:
            return "book.fill"
        case .music:
            return "music.note"
        case .camera:
            return "camera.fill"
        case .soccerBall:
            return "soccerball"
        case .bicycle:
            return "bicycle"
        case .paintPalette:
            return "paintpalette.fill"
        case .paintBrush:
            return "paintbrush.fill"
        case .scissors:
            return "scissors"
        case .pencil:
            return "pencil"
        case .ruler:
            return "ruler.fill"
        case .paperclip:
            return "paperclip"
        case .document:
            return "doc.text.fill"
        case .tag:
            return "tag.fill"
        case .hammer:
            return "hammer.fill"
        case .wrenchAndScrewdriver:
            return "wrench.and.screwdriver.fill"
        case .screwdriver:
            return "screwdriver.fill"
        case .powerPlug:
            return "powerplug.fill"
        case .cable:
            return "cable.connector"
        case .battery:
            return "battery.100"
        case .printer:
            return "printer.fill"
        case .laptop:
            return "laptopcomputer"
        case .house:
            return "house.fill"
        case .cup:
            return "cup.and.saucer.fill"
        case .utensils:
            return "fork.knife"
        case .shirt:
            return "tshirt.fill"
        case .bed:
            return "bed.double.fill"
        case .pawprint:
            return "pawprint.fill"
        case .medicalCase:
            return "cross.case.fill"
        case .bandage:
            return "bandage.fill"
        case .tent:
            return "tent.fill"
        case .car:
            return "car.fill"
        case .walking:
            return "figure.walk"
        case .map:
            return "map.fill"
        case .umbrella:
            return "umbrella.fill"
        case .flashlight:
            return "flashlight.off.fill"
        case .fan:
            return "fan.fill"
        case .flame:
            return "flame.fill"
        }
    }

    var category: ContainerIconCategory {
        switch self {
        case .shippingBox, .archiveBox, .trayStack, .folder, .bag, .suitcase, .backpack, .basket:
            return .storage
        case .tree, .snowflake, .leaf, .sun, .moonStars, .heart, .gift, .party:
            return .seasonal
        case .teddyBear, .puzzle, .gameController, .book, .music, .camera, .soccerBall, .bicycle:
            return .family
        case .paintPalette, .paintBrush, .scissors, .pencil, .ruler, .paperclip, .document, .tag:
            return .creative
        case .hammer, .wrenchAndScrewdriver, .screwdriver, .powerPlug, .cable, .battery, .printer, .laptop:
            return .tools
        case .house, .cup, .utensils, .shirt, .bed, .pawprint, .medicalCase, .bandage:
            return .home
        case .tent, .car, .walking, .map, .umbrella, .flashlight, .fan, .flame:
            return .outdoor
        }
    }

    var color: Color {
        switch category {
        case .storage:
            return .indigo
        case .seasonal:
            return .orange
        case .family:
            return .blue
        case .creative:
            return .pink
        case .tools:
            return .teal
        case .home:
            return .green
        case .outdoor:
            return .brown
        }
    }

    var uiColor: UIColor {
        UIColor(color)
    }

    var resolvedSymbolName: String {
        UIImage(systemName: symbolName) == nil ? "shippingbox.fill" : symbolName
    }

    static var groupedIcons: [(category: ContainerIconCategory, icons: [ContainerIcon])] {
        ContainerIconCategory.allCases.map { category in
            let icons = allCases.filter { $0.category == category }
            return (category, icons)
        }
    }

    static func title(for rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }

        return ContainerIcon(rawValue: rawValue)?.title
    }
}
