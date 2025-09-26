// cadence 1.0
import "NonFungibleToken"
import "SimpleNFT"


access(all) fun main(account: Address): [UInt64] {
    let acct = getAccount(account)

    // replace this with your collection's public path
    let cap = acct.capabilities.borrow<&SimpleNFT.Collection>(SimpleNFT.CollectionPublicPath)
        
    if cap == nil {
        return []
    }

    let ids: [UInt64] = cap!.getIDs()
    return ids
}
