import SimpleNFT from 0x0095f13a82f1a835
import NonFungibleToken from 0x631e88ae7f1d7c20

transaction {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {

        // Return early if the account already has a collection
        if signer.storage.borrow<&SimpleNFT.Collection>(from: SimpleNFT.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- SimpleNFT.createEmptyCollection(nftType: Type<@SimpleNFT.NFT>())

        // save it to the account
        signer.storage.save(<-collection, to: SimpleNFT.CollectionStoragePath)

        let collectionCap = signer.capabilities.storage.issue<&SimpleNFT.Collection>(SimpleNFT.CollectionStoragePath)
        signer.capabilities.publish(collectionCap, at: SimpleNFT.CollectionPublicPath)
    }
}
