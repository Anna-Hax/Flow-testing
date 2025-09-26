// cadence 1.0
import NonFungibleToken from 0x631e88ae7f1d7c20
import SimpleNFT from 0xac5b1841720e845a


access(all) fun main(account: Address, id: UInt64): [UInt64] {
    let acct = getAccount(account)

    // replace this with your collection's public path
    let cap = acct.capabilities.borrow<&SimpleNFT.Collection>(SimpleNFT.CollectionPublicPath)
        
    if cap == nil {
        return []
    }

    let ids: [UInt64] = cap!.getIDs()
    return ids
}
