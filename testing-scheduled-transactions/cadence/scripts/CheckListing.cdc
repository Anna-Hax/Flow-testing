// cadence 1.0
import SimpleScheduledMarketplace from 0xac5b1841720e845a

access(all) fun main(): {UInt64: {String: AnyStruct}} {
    let out: {UInt64: {String: AnyStruct}} = {}

    for id in SimpleScheduledMarketplace.itemsForSale.keys {
        let l = SimpleScheduledMarketplace.itemsForSale[id]!

        out[id] = {
            "tokenID": l.tokenID,
            "seller": l.seller,
            "basePrice": l.basePrice,
            "currentBid": l.currentBid,
            "highestBidder": l.highestBidder, // Address? or nil
            "endTime": l.endTime
        }
    }

    return out
}
