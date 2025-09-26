import FlowTransactionScheduler from 0x8c5303eaa26202d6 
import "FlowToken" 
import "FungibleToken"
import SimpleScheduledMarketplace from 0xac5b1841720e845a 
import ScheduleCallbackHandler from 0xac5b1841720e845a 
import "NonFungibleToken" 
import SimpleNFT  from 0xac5b1841720e845a
/// Schedule an increment of the Counter with a relative delay in seconds
transaction(
    delaySeconds: UFix64,
    priority: UInt8,
    executionEffort: UInt64,
    tokenID: UInt64,
    price: UFix64
) {
    let withdrawRef: auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}
    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.withdrawRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(from: SimpleNFT.CollectionStoragePath)
            ?? panic("Missing SimpleNFT collection")

        // Withdraw NFT from seller's collection (this requires signer's withdraw auth)
        let nft <- self.withdrawRef.withdraw(withdrawID: tokenID)

        // Pass the NFT resource and signer.address into contract
        let future = getCurrentBlock().timestamp + delaySeconds
        let listId: UInt64 = SimpleScheduledMarketplace.listItem(nft: <- nft, basePrice: price, seller: signer.address, endTime: future)
        let transactionData = ScheduleCallbackHandler.loradata(listingId: listId)

        let pr = priority == 0
            ? FlowTransactionScheduler.Priority.High
            : priority == 1
                ? FlowTransactionScheduler.Priority.Medium
                : FlowTransactionScheduler.Priority.Low

        let est = FlowTransactionScheduler.estimate(
            data: transactionData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort
        )

        assert(
            est.timestamp != nil || pr == FlowTransactionScheduler.Priority.Low,
            message: est.error ?? "estimation failed"
        )

        let vaultRef = signer.storage
            .borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("missing FlowToken vault")
        let fees <- vaultRef.withdraw(amount: est.flowFee ?? 0.0) as! @FlowToken.Vault

        let handlerCap = signer.capabilities.storage
            .issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(/storage/ScheduleCallbackHandler)

        let receipt <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap,
            data: transactionData,
            timestamp: future,
            priority: pr,
            executionEffort: executionEffort,
            fees: <-fees
        )

        log("Scheduled transaction id: ".concat(receipt.id.toString()).concat(" at ").concat(receipt.timestamp.toString()))
        
        destroy receipt
    }
}

