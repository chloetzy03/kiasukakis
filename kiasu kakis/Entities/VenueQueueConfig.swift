import Foundation

// A kind of table a venue seats, for example "3–4 people". Venues decide their own list, so none of this is hard-coded
// in the screens. Today it comes from a file in the app; later the same data can come from the venue itself.
struct TableType: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let minParty: Int
    let maxParty: Int
    // How this table's wait compares with the venue's usual wait. 1.0 is the same; bigger tables usually wait longer.
    let waitFactor: Double

    func fits(_ partySize: Int) -> Bool { (minParty...maxParty).contains(partySize) }
}

struct VenueQueueConfig: Codable, Equatable {
    let tableTypes: [TableType]

    var maxPartySize: Int { tableTypes.map(\.maxParty).max() ?? 1 }

    // The table a group of this size would get, or nil if the venue can't seat that many.
    func tableType(forParty partySize: Int) -> TableType? {
        tableTypes.first { $0.fits(partySize) }
    }

    // The venue's usual wait, adjusted for this group's table. nil stays nil: no data is never a wait.
    func waitMinutes(base: Int?, partySize: Int) -> Int? {
        guard let base else { return nil }
        let factor = tableType(forParty: partySize)?.waitFactor ?? 1
        return max(1, Int((Double(base) * factor).rounded()))
    }
}
