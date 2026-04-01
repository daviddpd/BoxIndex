import AppKit
import Foundation

private struct BoxIndexExportBundle: Codable {
    let schemaVersion: Int
    let exportedAt: Date
    let appName: String
    let containers: [ContainerExportRecord]
    let items: [ContainerItemExportRecord]
}

private struct ContainerExportRecord: Codable {
    let id: UUID
    let name: String
    let labelCode: String
    let location: String
    let subLocation: String?
    let notes: String?
    let colorTag: String?
    let photoFileName: String?
    let aliases: [String]
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
}

private struct ContainerItemExportRecord: Codable {
    let id: UUID
    let containerID: UUID
    let name: String
    let quantity: Int?
    let notes: String?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
}

private struct DemoItemTemplate {
    let name: String
    let tags: [String]
    let quantity: Int?
    let notes: String?
}

private struct DemoContainerTemplate {
    let name: String
    let labelCode: String
    let location: String
    let subLocation: String?
    let notes: String?
    let colorTag: String
    let aliases: [String]
    let symbolName: String
    let startColor: NSColor
    let endColor: NSColor
    let items: [DemoItemTemplate]
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x1234_5678_9ABC_DEF0 : seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

private let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
private let sampleDataRoot = projectRoot.appendingPathComponent("SampleData", isDirectory: true)
private let exportRoot = sampleDataRoot.appendingPathComponent("BoxIndex Household Demo Export", isDirectory: true)
private let attachmentsRoot = exportRoot.appendingPathComponent("attachments", isDirectory: true)

private func item(
    _ name: String,
    _ tags: [String],
    quantity: Int? = nil,
    notes: String? = nil
) -> DemoItemTemplate {
    DemoItemTemplate(name: name, tags: tags, quantity: quantity, notes: notes)
}

private let templates: [DemoContainerTemplate] = [
    .init(
        name: "Christmas Tree Decor",
        labelCode: "HD-001",
        location: "Attic",
        subLocation: "North Wall Rack",
        notes: "Main tree ornaments and lighting for the living room setup.",
        colorTag: "green",
        aliases: ["Holiday Tree", "Christmas Bin"],
        symbolName: "tree.fill",
        startColor: .init(deviceRed: 0.78, green: 0.88, blue: 0.78, alpha: 1),
        endColor: .init(deviceRed: 0.93, green: 0.97, blue: 0.91, alpha: 1),
        items: [
            item("Warm white string lights", ["holiday", "lights"], quantity: 4),
            item("Red glass ornaments", ["holiday", "ornaments"], quantity: 18),
            item("Silver shatterproof ornaments", ["holiday", "ornaments"], quantity: 24),
            item("Tree topper star", ["holiday", "tree"]),
            item("Velvet tree skirt", ["holiday", "tree"]),
            item("Stocking hooks", ["holiday", "mantel"], quantity: 6),
            item("Garland ties", ["holiday", "decor"], quantity: 12),
            item("Pinecone picks", ["holiday", "decor"], quantity: 10),
            item("Mini ornament hangers", ["holiday", "supplies"], quantity: 60),
            item("Spare light bulbs", ["holiday", "lights"], quantity: 8),
            item("Ribbon spools", ["holiday", "ribbon"], quantity: 3),
            item("Battery tea lights", ["holiday", "lights"], quantity: 12),
            item("Mantel garland clips", ["holiday", "hardware"], quantity: 10),
            item("Cord label tags", ["holiday", "organization"], quantity: 8),
            item("Santa figurine", ["holiday", "decor"]),
            item("Mini felt stockings", ["holiday", "decor"], quantity: 5),
            item("Bell garland", ["holiday", "decor"]),
            item("Wrapping paper bows", ["holiday", "gift wrap"], quantity: 20),
            item("Extension cord", ["holiday", "power"]),
            item("Storage bags for wreaths", ["holiday", "storage"], quantity: 2),
        ]
    ),
    .init(
        name: "Halloween Porch Decor",
        labelCode: "HD-002",
        location: "Garage",
        subLocation: "Top Shelf",
        notes: "Porch and entry decorations for trick-or-treat night.",
        colorTag: "amber",
        aliases: ["Halloween Tote", "Spooky Porch Bin"],
        symbolName: "moon.stars.fill",
        startColor: .init(deviceRed: 0.93, green: 0.80, blue: 0.58, alpha: 1),
        endColor: .init(deviceRed: 0.98, green: 0.93, blue: 0.84, alpha: 1),
        items: [
            item("LED pumpkin lanterns", ["holiday", "halloween"], quantity: 3),
            item("Spider web bags", ["holiday", "halloween"], quantity: 4),
            item("Plastic porch bats", ["holiday", "halloween"], quantity: 14),
            item("Skeleton welcome sign", ["holiday", "porch"]),
            item("Black flameless candles", ["holiday", "lighting"], quantity: 6),
            item("Orange fairy lights", ["holiday", "lights"], quantity: 2),
            item("Fog machine remote", ["holiday", "electronics"]),
            item("Mini tombstone stakes", ["holiday", "yard"], quantity: 5),
            item("Command outdoor hooks", ["holiday", "hardware"], quantity: 12),
            item("Candy bowl", ["holiday", "party"]),
            item("Witch hat garland", ["holiday", "decor"]),
            item("Glow stick necklaces", ["holiday", "party"], quantity: 20),
            item("Hanging spiders", ["holiday", "decor"], quantity: 8),
            item("Door wreath hanger", ["holiday", "hardware"]),
            item("Cauldron prop", ["holiday", "decor"]),
            item("Battery pack for lanterns", ["holiday", "power"]),
            item("Outdoor extension cord", ["holiday", "power"]),
            item("Pumpkin carving tools", ["holiday", "kitchen"]),
            item("Spare AA batteries", ["holiday", "power"], quantity: 16),
            item("Purple ribbon bundle", ["holiday", "craft"], quantity: 2),
        ]
    ),
    .init(
        name: "Easter & Spring Decor",
        labelCode: "HD-003",
        location: "Hall Closet",
        subLocation: "Upper Cubby",
        notes: "Seasonal table decor, eggs, and spring brunch accents.",
        colorTag: "coral",
        aliases: ["Spring Decor", "Easter Bin"],
        symbolName: "hare.fill",
        startColor: .init(deviceRed: 0.96, green: 0.86, blue: 0.84, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.95, blue: 0.91, alpha: 1),
        items: [
            item("Pastel egg garland", ["holiday", "spring"]),
            item("Plastic fillable eggs", ["holiday", "easter"], quantity: 30),
            item("Grass basket filler", ["holiday", "easter"], quantity: 2),
            item("Bunny table runner", ["holiday", "table"]),
            item("Ceramic rabbit figurines", ["holiday", "decor"], quantity: 2),
            item("Mini faux tulips", ["holiday", "floral"], quantity: 12),
            item("Cupcake toppers", ["holiday", "party"], quantity: 24),
            item("Brunch napkin rings", ["holiday", "table"], quantity: 8),
            item("Egg dye tablets", ["holiday", "craft"]),
            item("Paint brushes for eggs", ["holiday", "craft"], quantity: 5),
            item("Basket cellophane bags", ["holiday", "gift wrap"], quantity: 10),
            item("Ribbon curls", ["holiday", "gift wrap"], quantity: 4),
            item("Pastel paper straws", ["holiday", "party"], quantity: 20),
            item("Spring wreath sash", ["holiday", "decor"]),
            item("Place card holders", ["holiday", "table"], quantity: 6),
            item("Bunny ear headbands", ["holiday", "party"], quantity: 4),
            item("Fabric carrots", ["holiday", "decor"], quantity: 6),
            item("Mini chalkboard signs", ["holiday", "table"], quantity: 3),
            item("Treat bags", ["holiday", "party"], quantity: 16),
            item("Twine spool", ["holiday", "craft"]),
        ]
    ),
    .init(
        name: "Fall Harvest Decor",
        labelCode: "HD-004",
        location: "Basement",
        subLocation: "Seasonal Rack",
        notes: "Neutral fall decor for mantel, table, and front entry.",
        colorTag: "amber",
        aliases: ["Autumn Tote", "Harvest Bin"],
        symbolName: "leaf.fill",
        startColor: .init(deviceRed: 0.95, green: 0.84, blue: 0.66, alpha: 1),
        endColor: .init(deviceRed: 0.98, green: 0.94, blue: 0.86, alpha: 1),
        items: [
            item("Velvet pumpkins", ["holiday", "fall"], quantity: 7),
            item("Wood bead garland", ["holiday", "decor"]),
            item("Plaid table runner", ["holiday", "table"]),
            item("Amber candle holders", ["holiday", "decor"], quantity: 3),
            item("Battery pillar candles", ["holiday", "lights"], quantity: 4),
            item("Maple leaf picks", ["holiday", "floral"], quantity: 12),
            item("Mini hay bales", ["holiday", "decor"], quantity: 2),
            item("Lantern filler pinecones", ["holiday", "decor"]),
            item("Wheat stems", ["holiday", "floral"], quantity: 10),
            item("Thankful sign", ["holiday", "sign"]),
            item("Pumpkin spice candle tins", ["holiday", "candles"], quantity: 2),
            item("Jute ribbon", ["holiday", "craft"]),
            item("Buffalo plaid bows", ["holiday", "decor"], quantity: 6),
            item("Porch lantern timer", ["holiday", "electronics"]),
            item("Acorn bowl filler", ["holiday", "decor"]),
            item("Table place cards", ["holiday", "table"], quantity: 10),
            item("Napkin set", ["holiday", "table"], quantity: 8),
            item("Twinkle light strand", ["holiday", "lights"]),
            item("Door wreath hanger", ["holiday", "hardware"]),
            item("Crate risers", ["holiday", "display"], quantity: 2),
        ]
    ),
    .init(
        name: "Valentine Craft Box",
        labelCode: "HD-005",
        location: "Office Closet",
        subLocation: "Craft Shelf",
        notes: "Cards, classroom exchange extras, and heart-themed decorations.",
        colorTag: "coral",
        aliases: ["Valentine Box", "Heart Crafts"],
        symbolName: "heart.fill",
        startColor: .init(deviceRed: 0.96, green: 0.80, blue: 0.84, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.93, blue: 0.95, alpha: 1),
        items: [
            item("Cardstock hearts", ["holiday", "craft"], quantity: 40),
            item("Valentine stickers", ["holiday", "craft"], quantity: 3),
            item("Envelope pack", ["holiday", "stationery"], quantity: 20),
            item("Red ribbon", ["holiday", "craft"], quantity: 2),
            item("Pink pom poms", ["holiday", "craft"], quantity: 30),
            item("Glue sticks", ["holiday", "craft"], quantity: 12),
            item("Heart stamp set", ["holiday", "craft"]),
            item("Classroom valentines", ["holiday", "school"], quantity: 24),
            item("Treat bag toppers", ["holiday", "party"], quantity: 18),
            item("Baker's twine", ["holiday", "craft"]),
            item("Mini clothespins", ["holiday", "craft"], quantity: 20),
            item("Paper doilies", ["holiday", "craft"], quantity: 25),
            item("Red washi tape", ["holiday", "craft"], quantity: 4),
            item("Pink tissue paper", ["holiday", "gift wrap"], quantity: 8),
            item("Metallic pens", ["holiday", "craft"], quantity: 4),
            item("Heart cookie cutters", ["holiday", "kitchen"], quantity: 3),
            item("Cello bags", ["holiday", "gift wrap"], quantity: 15),
            item("Sparkly foam sheets", ["holiday", "craft"], quantity: 6),
            item("Conversation heart props", ["holiday", "party"]),
            item("Mini hole punch", ["holiday", "craft"]),
        ]
    ),
    .init(
        name: "Birthday Party Supplies",
        labelCode: "PT-006",
        location: "Garage",
        subLocation: "Party Shelf",
        notes: "Reusable supplies for family birthdays and backyard celebrations.",
        colorTag: "blue",
        aliases: ["Party Box", "Birthday Bin"],
        symbolName: "party.popper.fill",
        startColor: .init(deviceRed: 0.81, green: 0.89, blue: 0.97, alpha: 1),
        endColor: .init(deviceRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
        items: [
            item("Happy birthday banner", ["party", "birthday"]),
            item("Striped paper plates", ["party", "table"], quantity: 24),
            item("Paper cups", ["party", "table"], quantity: 24),
            item("Colorful napkins", ["party", "table"], quantity: 40),
            item("Reusable cake topper", ["party", "cake"]),
            item("String lights", ["party", "lights"], quantity: 2),
            item("Tablecloth clips", ["party", "hardware"], quantity: 8),
            item("Candles number set", ["party", "cake"]),
            item("Cupcake liners", ["party", "baking"], quantity: 50),
            item("Balloon pump", ["party", "supplies"]),
            item("Balloon bag", ["party", "supplies"], quantity: 40),
            item("Confetti packets", ["party", "decor"], quantity: 6),
            item("Treat bags", ["party", "favors"], quantity: 18),
            item("Favor box labels", ["party", "favors"], quantity: 24),
            item("Photo booth props", ["party", "decor"]),
            item("Tissue pom poms", ["party", "decor"], quantity: 8),
            item("Cake server", ["party", "serveware"]),
            item("Plastic serving tongs", ["party", "serveware"], quantity: 2),
            item("Outdoor extension cord", ["party", "power"]),
            item("Command hooks", ["party", "hardware"], quantity: 12),
        ]
    ),
    .init(
        name: "Kids Building Toys",
        labelCode: "KT-007",
        location: "Playroom",
        subLocation: "Cube Shelf 2",
        notes: "Loose construction toys and build accessories kept together for rainy days.",
        colorTag: "blue",
        aliases: ["Building Bin", "Block Tote"],
        symbolName: "building.blocks.fill",
        startColor: .init(deviceRed: 0.84, green: 0.90, blue: 0.98, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.98, blue: 1.0, alpha: 1),
        items: [
            item("Magnetic tiles", ["kids", "toys"], quantity: 52),
            item("Plastic building bricks", ["kids", "toys"], quantity: 120),
            item("Mini figures", ["kids", "toys"], quantity: 8),
            item("Wheel base pieces", ["kids", "toys"], quantity: 6),
            item("Ramp pieces", ["kids", "toys"], quantity: 4),
            item("Base plates", ["kids", "toys"], quantity: 5),
            item("Window pieces", ["kids", "toys"], quantity: 14),
            item("Animal block set", ["kids", "toys"], quantity: 10),
            item("Wooden stacking blocks", ["kids", "toys"], quantity: 24),
            item("Instruction booklets", ["kids", "toys"]),
            item("Storage zipper pouch", ["kids", "organization"]),
            item("Race car bodies", ["kids", "toys"], quantity: 6),
            item("Connector rods", ["kids", "toys"], quantity: 40),
            item("Gear pieces", ["kids", "toys"], quantity: 18),
            item("Small screwdriver tool", ["kids", "toys"]),
            item("Foam mat roads", ["kids", "toys"], quantity: 6),
            item("Marble run funnels", ["kids", "toys"], quantity: 12),
            item("Marble run tubes", ["kids", "toys"], quantity: 20),
            item("Build challenge cards", ["kids", "activity"]),
            item("Label pouch for missing pieces", ["kids", "organization"]),
        ]
    ),
    .init(
        name: "Kids Art Supplies",
        labelCode: "KT-008",
        location: "Playroom",
        subLocation: "Craft Cart Bottom",
        notes: "Everyday art materials for after-school projects and weekend crafts.",
        colorTag: "coral",
        aliases: ["Art Bin", "Craft Tote"],
        symbolName: "paintpalette.fill",
        startColor: .init(deviceRed: 0.96, green: 0.85, blue: 0.83, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.95, blue: 0.93, alpha: 1),
        items: [
            item("Construction paper pack", ["kids", "craft"]),
            item("Washable markers", ["kids", "craft"], quantity: 24),
            item("Crayon box", ["kids", "craft"], quantity: 64),
            item("Colored pencils", ["kids", "craft"], quantity: 24),
            item("Glue sticks", ["kids", "craft"], quantity: 16),
            item("Child scissors", ["kids", "craft"], quantity: 3),
            item("Pom poms", ["kids", "craft"], quantity: 60),
            item("Googly eyes", ["kids", "craft"], quantity: 80),
            item("Pipe cleaners", ["kids", "craft"], quantity: 50),
            item("Foam stickers", ["kids", "craft"], quantity: 4),
            item("Tempera paint set", ["kids", "paint"]),
            item("Watercolor tray", ["kids", "paint"]),
            item("Smocks", ["kids", "paint"], quantity: 2),
            item("Brush pack", ["kids", "paint"], quantity: 10),
            item("Craft tape", ["kids", "craft"], quantity: 6),
            item("Stamp pad", ["kids", "craft"], quantity: 3),
            item("Shape punches", ["kids", "craft"], quantity: 4),
            item("Sticker paper", ["kids", "craft"], quantity: 12),
            item("Glitter glue", ["kids", "craft"], quantity: 8),
            item("Sketch pads", ["kids", "craft"], quantity: 4),
        ]
    ),
    .init(
        name: "Family Board Games",
        labelCode: "KT-009",
        location: "Family Room",
        subLocation: "Cabinet Lower Shelf",
        notes: "Card games and compact board games stored together for easy weekend access.",
        colorTag: "slate",
        aliases: ["Game Crate", "Board Game Bin"],
        symbolName: "gamecontroller.fill",
        startColor: .init(deviceRed: 0.82, green: 0.86, blue: 0.92, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.97, blue: 0.99, alpha: 1),
        items: [
            item("Uno deck", ["games", "cards"]),
            item("Playing cards", ["games", "cards"], quantity: 3),
            item("Domino set", ["games", "tabletop"]),
            item("Yahtzee score pads", ["games", "tabletop"], quantity: 4),
            item("Chess pieces pouch", ["games", "tabletop"]),
            item("Checkers board", ["games", "tabletop"]),
            item("Travel bingo cards", ["games", "travel"]),
            item("Large dice set", ["games", "tabletop"], quantity: 6),
            item("Trivia cards", ["games", "cards"]),
            item("Pencil cup", ["games", "supplies"], quantity: 8),
            item("Dry erase markers", ["games", "supplies"], quantity: 5),
            item("Dry erase eraser", ["games", "supplies"]),
            item("Rule book folder", ["games", "organization"]),
            item("Sand timer", ["games", "supplies"]),
            item("Poker chips", ["games", "tabletop"], quantity: 40),
            item("Score pad clipboard", ["games", "supplies"]),
            item("Puzzle deck", ["games", "cards"]),
            item("Magnetic travel checkers", ["games", "travel"]),
            item("Token zip bags", ["games", "organization"], quantity: 12),
            item("Spare pencils", ["games", "supplies"], quantity: 10),
        ]
    ),
    .init(
        name: "Camping Gear Bin",
        labelCode: "HB-010",
        location: "Garage",
        subLocation: "Back Wall Shelf",
        notes: "Camp kitchen and campsite setup items that get packed into the car first.",
        colorTag: "green",
        aliases: ["Camp Bin", "Camp Kitchen Tote"],
        symbolName: "tent.fill",
        startColor: .init(deviceRed: 0.82, green: 0.89, blue: 0.80, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.98, blue: 0.92, alpha: 1),
        items: [
            item("Headlamps", ["camping", "lighting"], quantity: 4),
            item("Lantern", ["camping", "lighting"]),
            item("Tent stakes bag", ["camping", "hardware"]),
            item("Camp stove", ["camping", "kitchen"]),
            item("Fuel canister", ["camping", "kitchen"], quantity: 2),
            item("Roasting sticks", ["camping", "kitchen"], quantity: 6),
            item("Enamel mugs", ["camping", "kitchen"], quantity: 4),
            item("Mess kit", ["camping", "kitchen"]),
            item("Collapsible wash tub", ["camping", "kitchen"]),
            item("Fire starter cubes", ["camping", "supplies"]),
            item("Paracord bundle", ["camping", "supplies"]),
            item("Rechargeable battery pack", ["camping", "power"]),
            item("Bug spray", ["camping", "supplies"]),
            item("Sunscreen tube", ["camping", "supplies"]),
            item("Water jug spigot", ["camping", "kitchen"]),
            item("Marshmallow skewers", ["camping", "kitchen"], quantity: 8),
            item("Camp towel", ["camping", "soft goods"], quantity: 2),
            item("Folding spatula", ["camping", "kitchen"]),
            item("Dish soap bottle", ["camping", "kitchen"]),
            item("First aid refill pouch", ["camping", "safety"]),
        ]
    ),
    .init(
        name: "Beach Day Tote",
        labelCode: "HB-011",
        location: "Mudroom",
        subLocation: "Bench Storage",
        notes: "Grab-and-go beach and pool-day supplies for summer weekends.",
        colorTag: "blue",
        aliases: ["Beach Tote", "Summer Beach Bag"],
        symbolName: "beach.umbrella.fill",
        startColor: .init(deviceRed: 0.82, green: 0.91, blue: 0.98, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.98, blue: 1.0, alpha: 1),
        items: [
            item("Beach towels", ["beach", "summer"], quantity: 4),
            item("Mesh toy bag", ["beach", "organization"]),
            item("Sand toys", ["beach", "kids"], quantity: 12),
            item("Sunscreen bottles", ["beach", "summer"], quantity: 3),
            item("Foldable shovel", ["beach", "kids"]),
            item("Goggles", ["beach", "swim"], quantity: 4),
            item("Water shoes", ["beach", "swim"], quantity: 2),
            item("Compact first aid kit", ["beach", "safety"]),
            item("Reusable water bottles", ["beach", "summer"], quantity: 4),
            item("Snorkel masks", ["beach", "swim"], quantity: 2),
            item("Waterproof phone pouch", ["beach", "electronics"], quantity: 2),
            item("Shade anchor stakes", ["beach", "hardware"], quantity: 4),
            item("Picnic blanket", ["beach", "summer"]),
            item("Sun hat clips", ["beach", "summer"], quantity: 4),
            item("Wet bag", ["beach", "organization"], quantity: 2),
            item("After-sun lotion", ["beach", "summer"]),
            item("Frisbee", ["beach", "games"]),
            item("Beach ball", ["beach", "games"]),
            item("Zip snack containers", ["beach", "kitchen"], quantity: 6),
            item("Cooling towel", ["beach", "summer"], quantity: 2),
        ]
    ),
    .init(
        name: "Cables & Chargers",
        labelCode: "HB-012",
        location: "Office Closet",
        subLocation: "Plastic Drawer 3",
        notes: "Spare everyday cables sorted for quick tech replacement.",
        colorTag: "slate",
        aliases: ["Cable Bin", "Chargers Drawer"],
        symbolName: "cable.connector",
        startColor: .init(deviceRed: 0.82, green: 0.85, blue: 0.90, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.97, blue: 0.99, alpha: 1),
        items: [
            item("USB-C charging cables", ["tech", "cables"], quantity: 8),
            item("Lightning cables", ["tech", "cables"], quantity: 6),
            item("Micro USB cables", ["tech", "cables"], quantity: 4),
            item("USB wall bricks", ["tech", "power"], quantity: 7),
            item("Travel power strip", ["tech", "power"]),
            item("Cable labels", ["tech", "organization"], quantity: 20),
            item("Velcro cable ties", ["tech", "organization"], quantity: 30),
            item("HDMI cable", ["tech", "video"], quantity: 3),
            item("Ethernet cable", ["tech", "network"], quantity: 2),
            item("USB-C hub", ["tech", "adapters"]),
            item("Laptop charger", ["tech", "power"], quantity: 2),
            item("Portable battery pack", ["tech", "power"], quantity: 2),
            item("SD card case", ["tech", "storage"]),
            item("USB flash drives", ["tech", "storage"], quantity: 5),
            item("Audio aux cable", ["tech", "audio"], quantity: 3),
            item("International plug adapters", ["tech", "travel"]),
            item("Outlet splitter", ["tech", "power"], quantity: 4),
            item("Watch charging puck", ["tech", "power"]),
            item("Label maker tape", ["tech", "organization"]),
            item("Small zip pouches", ["tech", "organization"], quantity: 5),
        ]
    ),
    .init(
        name: "Power Tool Accessories",
        labelCode: "HB-013",
        location: "Garage",
        subLocation: "Workbench Cabinet",
        notes: "Accessories and consumables for the drill, driver, and circular saw.",
        colorTag: "amber",
        aliases: ["Tool Case", "Drill Accessories"],
        symbolName: "hammer.fill",
        startColor: .init(deviceRed: 0.93, green: 0.83, blue: 0.67, alpha: 1),
        endColor: .init(deviceRed: 0.98, green: 0.95, blue: 0.87, alpha: 1),
        items: [
            item("Drill bit set", ["tools", "hardware"]),
            item("Driver bit set", ["tools", "hardware"]),
            item("Magnetic bit holder", ["tools", "hardware"], quantity: 2),
            item("Tape measure", ["tools", "hardware"], quantity: 2),
            item("Utility knife blades", ["tools", "hardware"], quantity: 20),
            item("Painter's tape", ["tools", "supplies"], quantity: 4),
            item("Wood screws 1 inch", ["tools", "fasteners"], quantity: 50),
            item("Wood screws 2 inch", ["tools", "fasteners"], quantity: 40),
            item("Wall anchors", ["tools", "fasteners"], quantity: 30),
            item("Sandpaper sheets", ["tools", "supplies"], quantity: 18),
            item("Safety glasses", ["tools", "safety"], quantity: 2),
            item("Work gloves", ["tools", "safety"], quantity: 2),
            item("Hearing protection", ["tools", "safety"]),
            item("Dust masks", ["tools", "safety"], quantity: 12),
            item("Stud finder battery", ["tools", "electronics"]),
            item("Hole saw kit", ["tools", "hardware"]),
            item("Spare reciprocating saw blades", ["tools", "hardware"], quantity: 6),
            item("Countersink bit", ["tools", "hardware"]),
            item("Pocket hole screws", ["tools", "fasteners"], quantity: 40),
            item("Hex key set", ["tools", "hardware"]),
        ]
    ),
    .init(
        name: "Painting Supplies Tote",
        labelCode: "HB-014",
        location: "Laundry Room",
        subLocation: "Upper Shelf",
        notes: "Touch-up painting and small weekend project supplies.",
        colorTag: "coral",
        aliases: ["Paint Tote", "DIY Paint Bin"],
        symbolName: "paintbrush.pointed.fill",
        startColor: .init(deviceRed: 0.95, green: 0.84, blue: 0.82, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.94, blue: 0.92, alpha: 1),
        items: [
            item("2-inch angled brush", ["paint", "diy"], quantity: 2),
            item("Foam brush pack", ["paint", "diy"], quantity: 8),
            item("Mini roller frame", ["paint", "diy"]),
            item("Roller covers", ["paint", "diy"], quantity: 6),
            item("Paint tray liners", ["paint", "diy"], quantity: 10),
            item("Drop cloth", ["paint", "diy"], quantity: 2),
            item("Blue painter's tape", ["paint", "supplies"], quantity: 5),
            item("Sandpaper sponge", ["paint", "supplies"], quantity: 6),
            item("Spackle tub", ["paint", "repair"]),
            item("Putty knife", ["paint", "repair"]),
            item("Touch-up wall paint", ["paint", "storage"], quantity: 3),
            item("Trim paint sample", ["paint", "storage"]),
            item("Mixing sticks", ["paint", "supplies"], quantity: 12),
            item("Disposable gloves", ["paint", "safety"], quantity: 20),
            item("Respirator mask", ["paint", "safety"]),
            item("Caulk tube", ["paint", "repair"], quantity: 2),
            item("Caulk smoother", ["paint", "repair"]),
            item("Label tape for paint cans", ["paint", "organization"]),
            item("Plastic sheeting", ["paint", "supplies"]),
            item("Rag bag", ["paint", "cleanup"]),
        ]
    ),
    .init(
        name: "Sewing & Mending Box",
        labelCode: "HB-015",
        location: "Guest Room Closet",
        subLocation: "Fabric Bin Stack",
        notes: "Basic mending tools, spare notions, and quick fix supplies.",
        colorTag: "slate",
        aliases: ["Sewing Box", "Mending Kit"],
        symbolName: "scissors",
        startColor: .init(deviceRed: 0.84, green: 0.86, blue: 0.91, alpha: 1),
        endColor: .init(deviceRed: 0.96, green: 0.97, blue: 0.99, alpha: 1),
        items: [
            item("Thread spools", ["sewing", "hobby"], quantity: 18),
            item("Hand needles", ["sewing", "hobby"], quantity: 12),
            item("Safety pins", ["sewing", "hobby"], quantity: 40),
            item("Seam ripper", ["sewing", "hobby"]),
            item("Fabric scissors", ["sewing", "hobby"]),
            item("Measuring tape", ["sewing", "hobby"]),
            item("Straight pins", ["sewing", "hobby"], quantity: 100),
            item("Pin cushion", ["sewing", "hobby"]),
            item("Elastic rolls", ["sewing", "hobby"], quantity: 3),
            item("Iron-on patches", ["sewing", "repair"], quantity: 6),
            item("Bias tape", ["sewing", "hobby"], quantity: 4),
            item("Buttons assorted", ["sewing", "repair"], quantity: 50),
            item("Hook and eye set", ["sewing", "repair"]),
            item("Zippers assorted", ["sewing", "repair"], quantity: 8),
            item("Embroidery hoop", ["sewing", "hobby"]),
            item("Marking chalk", ["sewing", "hobby"], quantity: 3),
            item("Thimble", ["sewing", "hobby"]),
            item("Hem tape", ["sewing", "repair"], quantity: 2),
            item("Small fabric scraps", ["sewing", "hobby"], quantity: 12),
            item("Needle threader", ["sewing", "hobby"], quantity: 2),
        ]
    ),
    .init(
        name: "Garden Supplies Bin",
        labelCode: "HB-016",
        location: "Garage",
        subLocation: "Side Door Rack",
        notes: "Small gardening tools and seasonal planting supplies.",
        colorTag: "green",
        aliases: ["Garden Bin", "Planting Tote"],
        symbolName: "leaf.circle.fill",
        startColor: .init(deviceRed: 0.82, green: 0.90, blue: 0.80, alpha: 1),
        endColor: .init(deviceRed: 0.95, green: 0.98, blue: 0.92, alpha: 1),
        items: [
            item("Hand trowel", ["garden", "outdoor"]),
            item("Hand rake", ["garden", "outdoor"]),
            item("Gardening gloves", ["garden", "outdoor"], quantity: 2),
            item("Plant ties", ["garden", "outdoor"], quantity: 30),
            item("Seed packets", ["garden", "outdoor"], quantity: 12),
            item("Plant markers", ["garden", "outdoor"], quantity: 20),
            item("Twine spool", ["garden", "outdoor"]),
            item("Pruning shears", ["garden", "outdoor"]),
            item("Fertilizer scoop", ["garden", "outdoor"]),
            item("Watering wand nozzle", ["garden", "outdoor"]),
            item("Pot risers", ["garden", "outdoor"], quantity: 6),
            item("Garden snips", ["garden", "outdoor"]),
            item("Kneeling pad", ["garden", "outdoor"]),
            item("Bulb planter", ["garden", "outdoor"]),
            item("Slug bait container", ["garden", "outdoor"]),
            item("Soil moisture meter", ["garden", "outdoor"]),
            item("Spray bottle", ["garden", "outdoor"], quantity: 2),
            item("Coco coir discs", ["garden", "outdoor"], quantity: 8),
            item("Mini nursery pots", ["garden", "outdoor"], quantity: 14),
            item("Harvest basket", ["garden", "outdoor"]),
        ]
    ),
    .init(
        name: "Pet Care Supplies",
        labelCode: "HB-017",
        location: "Laundry Room",
        subLocation: "Cabinet Floor",
        notes: "Backup grooming and travel supplies for the dog and cat.",
        colorTag: "blue",
        aliases: ["Pet Bin", "Dog & Cat Supplies"],
        symbolName: "pawprint.fill",
        startColor: .init(deviceRed: 0.83, green: 0.91, blue: 0.97, alpha: 1),
        endColor: .init(deviceRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
        items: [
            item("Travel water bowl", ["pets", "travel"]),
            item("Backup leash", ["pets", "walks"]),
            item("Waste bag rolls", ["pets", "walks"], quantity: 8),
            item("Pet wipes", ["pets", "care"]),
            item("Brush", ["pets", "care"]),
            item("Nail clippers", ["pets", "care"]),
            item("Tick remover tool", ["pets", "care"]),
            item("Pet shampoo", ["pets", "bath"]),
            item("Treat pouch", ["pets", "training"]),
            item("Clicker", ["pets", "training"]),
            item("Car seat tether", ["pets", "travel"]),
            item("Flea comb", ["pets", "care"]),
            item("Pet towel", ["pets", "care"], quantity: 2),
            item("Food scoop", ["pets", "feeding"]),
            item("Slow feeder insert", ["pets", "feeding"]),
            item("Collapsible crate pad", ["pets", "travel"]),
            item("Extra collar tags", ["pets", "organization"], quantity: 2),
            item("Lint roller", ["pets", "cleanup"], quantity: 3),
            item("Toy repair sewing kit", ["pets", "repair"]),
            item("Small first aid pouch", ["pets", "safety"]),
        ]
    ),
    .init(
        name: "Winter Accessories Tote",
        labelCode: "HB-018",
        location: "Coat Closet",
        subLocation: "Upper Shelf",
        notes: "Cold-weather extras that don't fit on the main hook rail.",
        colorTag: "slate",
        aliases: ["Winter Tote", "Snow Gear Bin"],
        symbolName: "snowflake",
        startColor: .init(deviceRed: 0.84, green: 0.89, blue: 0.97, alpha: 1),
        endColor: .init(deviceRed: 0.96, green: 0.98, blue: 1.0, alpha: 1),
        items: [
            item("Knit hats", ["winter", "clothing"], quantity: 8),
            item("Wool scarves", ["winter", "clothing"], quantity: 5),
            item("Waterproof gloves", ["winter", "clothing"], quantity: 4),
            item("Hand warmers", ["winter", "supplies"], quantity: 20),
            item("Thermal socks", ["winter", "clothing"], quantity: 6),
            item("Snow pants clips", ["winter", "clothing"], quantity: 4),
            item("Sled tow rope", ["winter", "outdoor"]),
            item("Ice scraper", ["winter", "car"]),
            item("Spare beanies", ["winter", "clothing"], quantity: 3),
            item("Ear warmers", ["winter", "clothing"], quantity: 4),
            item("Boot dryer packets", ["winter", "supplies"], quantity: 6),
            item("Reusable hot packs", ["winter", "supplies"], quantity: 4),
            item("Ski goggles case", ["winter", "outdoor"]),
            item("Helmet liners", ["winter", "outdoor"], quantity: 2),
            item("Snow boot laces", ["winter", "repair"], quantity: 3),
            item("Reflective slap bands", ["winter", "safety"], quantity: 4),
            item("Lip balm bundle", ["winter", "care"], quantity: 5),
            item("Moisturizing lotion", ["winter", "care"]),
            item("Glove clips", ["winter", "organization"], quantity: 6),
            item("Spare mitten labels", ["winter", "organization"], quantity: 10),
        ]
    ),
    .init(
        name: "Baby Keepsakes Box",
        labelCode: "HB-019",
        location: "Primary Closet",
        subLocation: "Top Shelf",
        notes: "Special keepsakes and favorite early baby items.",
        colorTag: "coral",
        aliases: ["Keepsake Box", "Baby Memory Box"],
        symbolName: "gift.fill",
        startColor: .init(deviceRed: 0.96, green: 0.86, blue: 0.84, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.95, blue: 0.94, alpha: 1),
        items: [
            item("Hospital hat", ["keepsake", "baby"]),
            item("Baby blanket", ["keepsake", "baby"]),
            item("First shoes", ["keepsake", "baby"]),
            item("Coming home outfit", ["keepsake", "baby"]),
            item("Birth announcement cards", ["keepsake", "paper"]),
            item("Baby bracelet", ["keepsake", "memory"]),
            item("Ultrasound prints", ["keepsake", "paper"]),
            item("First birthday candle", ["keepsake", "memory"]),
            item("Favorite board book", ["keepsake", "baby"]),
            item("Milestone cards", ["keepsake", "paper"]),
            item("Tiny socks", ["keepsake", "baby"], quantity: 2),
            item("Baby teeth envelope", ["keepsake", "memory"]),
            item("Lock of hair envelope", ["keepsake", "memory"]),
            item("Footprint art", ["keepsake", "paper"]),
            item("NICU badge holder", ["keepsake", "memory"]),
            item("Family photo strip", ["keepsake", "paper"]),
            item("Baby shower ribbon", ["keepsake", "memory"]),
            item("Special pacifier", ["keepsake", "baby"]),
            item("Handwritten notes", ["keepsake", "paper"]),
            item("First holiday ornament", ["keepsake", "memory"]),
        ]
    ),
    .init(
        name: "Emergency Supply Bin",
        labelCode: "HB-020",
        location: "Garage",
        subLocation: "Near Door Shelf",
        notes: "Backup essentials kept together for outages and quick evacuations.",
        colorTag: "amber",
        aliases: ["Emergency Bin", "Power Outage Tote"],
        symbolName: "cross.case.fill",
        startColor: .init(deviceRed: 0.95, green: 0.86, blue: 0.72, alpha: 1),
        endColor: .init(deviceRed: 0.99, green: 0.95, blue: 0.88, alpha: 1),
        items: [
            item("Flashlights", ["emergency", "safety"], quantity: 4),
            item("Lantern", ["emergency", "safety"]),
            item("AA batteries", ["emergency", "power"], quantity: 24),
            item("AAA batteries", ["emergency", "power"], quantity: 16),
            item("Battery radio", ["emergency", "safety"]),
            item("First aid kit", ["emergency", "medical"]),
            item("Bottled water", ["emergency", "supplies"], quantity: 12),
            item("Protein bars", ["emergency", "supplies"], quantity: 10),
            item("N95 masks", ["emergency", "medical"], quantity: 12),
            item("Work gloves", ["emergency", "safety"], quantity: 2),
            item("Emergency blanket", ["emergency", "safety"], quantity: 4),
            item("Phone charging cable", ["emergency", "power"], quantity: 2),
            item("Portable power bank", ["emergency", "power"]),
            item("Whistle", ["emergency", "safety"], quantity: 2),
            item("Waterproof matches", ["emergency", "safety"]),
            item("Duct tape", ["emergency", "repair"]),
            item("Multi-tool", ["emergency", "tools"]),
            item("Notepad", ["emergency", "supplies"]),
            item("Permanent marker", ["emergency", "supplies"], quantity: 2),
            item("Zip bags", ["emergency", "organization"], quantity: 12),
        ]
    ),
]

private func writeText(_ text: String, to url: URL) throws {
    try text.write(to: url, atomically: true, encoding: .utf8)
}

private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    try encoder.encode(value).write(to: url, options: [.atomic])
}

private func csvField(_ value: String) -> String {
    "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
}

private func writeCSV(headers: [String], rows: [[String]], to url: URL) throws {
    let csv = ([headers] + rows)
        .map { row in row.map(csvField).joined(separator: ",") }
        .joined(separator: "\n")
    try writeText(csv, to: url)
}

private func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

private func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

private func drawText(
    _ text: String,
    in rect: CGRect,
    font: NSFont,
    color: NSColor,
    alignment: NSTextAlignment = .left,
    lineHeightMultiple: CGFloat = 1.0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineHeightMultiple = lineHeightMultiple

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]

    NSAttributedString(string: text, attributes: attributes).draw(in: rect)
}

private func renderImage(
    for template: DemoContainerTemplate,
    outputURL: URL
) throws {
    let width = 1400
    let height = 1050

    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ),
        let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)
    else {
        throw NSError(domain: "GenerateDemoExport", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext
    let rect = CGRect(x: 0, y: 0, width: width, height: height)

    let background = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            template.startColor.usingColorSpace(.deviceRGB)!.cgColor,
            template.endColor.usingColorSpace(.deviceRGB)!.cgColor,
        ] as CFArray,
        locations: [0, 1]
    )!

    context.drawLinearGradient(
        background,
        start: CGPoint(x: 0, y: rect.height),
        end: CGPoint(x: rect.width, y: 0),
        options: []
    )

    context.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    context.fillEllipse(in: CGRect(x: -50, y: 640, width: 420, height: 420))
    context.fillEllipse(in: CGRect(x: 1030, y: 90, width: 280, height: 280))

    let panelRect = CGRect(x: 86, y: 88, width: rect.width - 172, height: rect.height - 176)
    let panelPath = roundedRect(panelRect, radius: 48)
    NSColor.white.withAlphaComponent(0.78).setFill()
    panelPath.fill()

    let tagRect = CGRect(x: panelRect.minX + 44, y: panelRect.maxY - 118, width: 240, height: 54)
    let tagPath = roundedRect(tagRect, radius: 27)
    NSColor.white.withAlphaComponent(0.92).setFill()
    tagPath.fill()

    drawText(
        template.labelCode,
        in: CGRect(x: tagRect.minX, y: tagRect.minY + 10, width: tagRect.width, height: 34),
        font: .systemFont(ofSize: 26, weight: .bold),
        color: NSColor(deviceWhite: 0.14, alpha: 1),
        alignment: .center
    )

    if let symbol = NSImage(systemSymbolName: template.symbolName, accessibilityDescription: nil)
        ?? NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: nil) {
        let symbolRect = CGRect(x: panelRect.minX + 760, y: panelRect.minY + 250, width: 360, height: 360)
        symbol.draw(in: symbolRect)
    }

    drawText(
        template.name,
        in: CGRect(x: panelRect.minX + 44, y: panelRect.maxY - 250, width: 620, height: 120),
        font: .systemFont(ofSize: 66, weight: .bold),
        color: NSColor(deviceWhite: 0.10, alpha: 1),
        alignment: .left,
        lineHeightMultiple: 0.92
    )

    drawText(
        template.location + (template.subLocation.map { " • \($0)" } ?? ""),
        in: CGRect(x: panelRect.minX + 48, y: panelRect.maxY - 330, width: 620, height: 42),
        font: .systemFont(ofSize: 28, weight: .semibold),
        color: NSColor(deviceWhite: 0.22, alpha: 0.88)
    )

    drawText(
        template.notes ?? "Household demo container photo",
        in: CGRect(x: panelRect.minX + 48, y: panelRect.maxY - 414, width: 620, height: 96),
        font: .systemFont(ofSize: 24, weight: .medium),
        color: NSColor(deviceWhite: 0.25, alpha: 0.82),
        alignment: .left,
        lineHeightMultiple: 1.1
    )

    let chipSpecs: [(String, CGRect)] = [
        ("BoxIndex demo photo", CGRect(x: panelRect.minX + 48, y: panelRect.minY + 118, width: 230, height: 44)),
        ("Local-first storage", CGRect(x: panelRect.minX + 292, y: panelRect.minY + 118, width: 230, height: 44)),
        ("\(template.items.count) item ideas", CGRect(x: panelRect.minX + 536, y: panelRect.minY + 118, width: 210, height: 44)),
    ]

    for (text, chipRect) in chipSpecs {
        let chipPath = roundedRect(chipRect, radius: 22)
        NSColor.white.withAlphaComponent(0.88).setFill()
        chipPath.fill()
        drawText(
            text,
            in: CGRect(x: chipRect.minX, y: chipRect.minY + 9, width: chipRect.width, height: 28),
            font: .systemFont(ofSize: 18, weight: .semibold),
            color: NSColor(deviceWhite: 0.22, alpha: 1),
            alignment: .center
        )
    }

    let footerRect = CGRect(x: panelRect.minX + 48, y: panelRect.minY + 54, width: panelRect.width - 96, height: 34)
    drawText(
        "Generated sample data for screenshots and import testing",
        in: footerRect,
        font: .systemFont(ofSize: 18, weight: .regular),
        color: NSColor(deviceWhite: 0.28, alpha: 0.72),
        alignment: .left
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.90]) else {
        throw NSError(domain: "GenerateDemoExport", code: 2)
    }

    try data.write(to: outputURL, options: [.atomic])
}

private func iso8601(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
}

private func sanitizedPhotoFileName(for template: DemoContainerTemplate, id: UUID) -> String {
    let base = template.labelCode.lowercased() + "-" + template.name.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "&", with: "and")
    return "\(id.uuidString)-\(base).jpg"
}

private func buildDemoExport() throws {
    if FileManager.default.fileExists(atPath: exportRoot.path) {
        try FileManager.default.removeItem(at: exportRoot)
    }

    try ensureDirectory(sampleDataRoot)
    try ensureDirectory(exportRoot)
    try ensureDirectory(attachmentsRoot)

    var generator = SeededGenerator(seed: 0xB01D13AF)
    let calendar = Calendar(identifier: .gregorian)
    let baseDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5, hour: 10, minute: 0))!

    var containers: [ContainerExportRecord] = []
    var items: [ContainerItemExportRecord] = []

    for (index, template) in templates.enumerated() {
        let containerID = UUID()
        let createdAt = calendar.date(byAdding: .day, value: index * 9, to: baseDate)!
        let updatedAt = calendar.date(byAdding: .day, value: index * 9 + 24, to: baseDate)!
        let photoFileName = sanitizedPhotoFileName(for: template, id: containerID)
        let photoURL = attachmentsRoot.appendingPathComponent(photoFileName)
        try renderImage(for: template, outputURL: photoURL)

        containers.append(
            ContainerExportRecord(
                id: containerID,
                name: template.name,
                labelCode: template.labelCode,
                location: template.location,
                subLocation: template.subLocation,
                notes: template.notes,
                colorTag: template.colorTag,
                photoFileName: photoFileName,
                aliases: template.aliases,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: false
            )
        )

        let itemCount = Int.random(in: 3...20, using: &generator)
        let selectedTemplates = Array(template.items.shuffled(using: &generator).prefix(itemCount))

        for (itemIndex, itemTemplate) in selectedTemplates.enumerated() {
            let itemCreatedAt = calendar.date(byAdding: .hour, value: itemIndex * 6, to: createdAt)!
            let itemUpdatedAt = calendar.date(byAdding: .hour, value: itemIndex * 4 + 2, to: updatedAt)!

            let quantity: Int?
            if let baseQuantity = itemTemplate.quantity {
                quantity = baseQuantity
            } else if Int.random(in: 0...99, using: &generator) < 40 {
                quantity = Int.random(in: 1...6, using: &generator)
            } else {
                quantity = nil
            }

            let notes: String?
            if let itemNote = itemTemplate.notes {
                notes = itemNote
            } else if Int.random(in: 0...99, using: &generator) < 25 {
                let notePool = [
                    "Usually packed near the top.",
                    "Check before buying duplicates.",
                    "Used most often during setup.",
                    "Keep together with matching accessories.",
                    "Good spare to have on hand.",
                ]
                notes = notePool[Int.random(in: 0..<(notePool.count), using: &generator)]
            } else {
                notes = nil
            }

            items.append(
                ContainerItemExportRecord(
                    id: UUID(),
                    containerID: containerID,
                    name: itemTemplate.name,
                    quantity: quantity,
                    notes: notes,
                    tags: itemTemplate.tags,
                    createdAt: itemCreatedAt,
                    updatedAt: itemUpdatedAt
                )
            )
        }
    }

    let bundle = BoxIndexExportBundle(
        schemaVersion: 1,
        exportedAt: calendar.date(byAdding: .day, value: 210, to: baseDate)!,
        appName: "BoxIndex",
        containers: containers,
        items: items
    )

    try writeJSON(bundle, to: exportRoot.appendingPathComponent("boxindex-export.json"))
    try writeJSON(containers, to: exportRoot.appendingPathComponent("containers.json"))
    try writeJSON(items, to: exportRoot.appendingPathComponent("items.json"))

    try writeCSV(
        headers: ["id", "name", "labelCode", "location", "subLocation", "notes", "colorTag", "photoFileName", "aliases", "createdAt", "updatedAt", "isArchived"],
        rows: containers.map { record in
            [
                record.id.uuidString,
                record.name,
                record.labelCode,
                record.location,
                record.subLocation ?? "",
                record.notes ?? "",
                record.colorTag ?? "",
                record.photoFileName ?? "",
                record.aliases.joined(separator: "|"),
                iso8601(record.createdAt),
                iso8601(record.updatedAt),
                record.isArchived ? "true" : "false",
            ]
        },
        to: exportRoot.appendingPathComponent("containers.csv")
    )

    try writeCSV(
        headers: ["id", "containerID", "name", "quantity", "notes", "tags", "createdAt", "updatedAt"],
        rows: items.map { record in
            [
                record.id.uuidString,
                record.containerID.uuidString,
                record.name,
                record.quantity.map(String.init) ?? "",
                record.notes ?? "",
                record.tags.joined(separator: "|"),
                iso8601(record.createdAt),
                iso8601(record.updatedAt),
            ]
        },
        to: exportRoot.appendingPathComponent("items.csv")
    )

    try writeText(
        """
        BoxIndex Household Demo Export

        Import this entire folder into BoxIndex if you want the 20 generated container photos to come along with the JSON data.
        If you import only boxindex-export.json, the records will import but the photos will not.
        """,
        to: exportRoot.appendingPathComponent("README.txt")
    )

    print("Generated demo export at \(exportRoot.path)")
    print("Containers: \(containers.count)")
    print("Items: \(items.count)")
    print("Attachments: \(templates.count)")
}

try buildDemoExport()
