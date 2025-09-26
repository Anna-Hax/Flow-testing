# Technical Report: Discrepancy in Smart Contract Behavior Between Flow Emulator and Testnet

## 1\. Summary

This report details a critical discrepancy observed in the behavior of a scheduled NFT auction marketplace contract (`SimpleScheduledMarketplace`) when deployed on the Flow Testnet versus the Flow Emulator. While the complete auction lifecycle—listing, bidding, and settlement—functions correctly on the emulator, the testnet execution fails at the final step. Specifically, the financial settlement succeeds, but the NFT transfer to the auction winner fails, leaving the asset stranded in the marketplace contract's collection.

## 2\. Project Overview

The system consists of two primary Cadence contracts:

  * **`SimpleNFT`**: A standard NFT contract implementation.
  * **`SimpleScheduledMarketplace`**: An auction house contract that holds listed NFTs. It uses the Flow Scheduler to automatically trigger an auction completion function after a specified duration.

The core logic of the `completeAuction` function is to:

1.  Identify the highest bidder.
2.  Transfer the winning bid amount from the marketplace's vault to the seller, after deducting a percentage-based fee for the marketplace owner.
3.  Transfer the auctioned NFT from the marketplace's collection to the winning bidder.

## 3\. Addresses for testnet testing:
1. The contracts - [ac5b1841720e845a](https://testnet.flowscan.io/account/0xac5b1841720e845a)
2. The account creating Listings - [5542f6363675f0cd](https://testnet.flowscan.io/account/0x5542f6363675f0cd?collectionName=A.ac5b1841720e845a.SimpleNFT.NFT&tab=nft-collections)
3. The account bidding - [b1254feb278ff012](https://testnet.flowscan.io/account/0xb1254feb278ff012)

## 4\. Expected Workflow and Testing Procedure

The standard operational workflow for testing the contract functionality is as follows:

1.  **Setup**: Create and configure `SimpleNFT` collections for two distinct accounts (a "seller" and a "bidder").
2.  **Mint**: Mint an NFT into the seller's collection.
3.  **List**: The seller executes the `CreateListing.cdc` transaction to list the NFT for auction. This transaction schedules the future execution of the `completeAuction` function.
4.  **Bid**: The bidder account places a bid on the listed NFT.
5.  **Monitor**: Track the auction's status using a script.
6.  **Verification**: After the scheduled auction completion time has passed, verify that:
      * The NFT has been transferred to the bidder's collection.
      * The seller and marketplace owner have received their respective funds.
      * All relevant events (`Listed`, `BidPlaced`, `AuctionCompleted`) have been emitted correctly.

## 5\. Observed Behavior and Discrepancy

### 5.1. On Flow Emulator

The contract and all associated transactions performed exactly as expected. The entire workflow was successful, culminating in the correct transfer of both funds and the NFT asset.

### 5.2. On Flow Testnet

A critical deviation was observed during testnet execution. While the financial aspects of the auction completed correctly, the asset transfer failed.

  * **Successful Operations**:

      * The winning bid amount was successfully processed.
      * The marketplace fee was correctly deducted and transferred to the owner's account.
      * The remaining amount was correctly transferred to the NFT seller's account.
      * The `AuctionCompleted` event was emitted.

  * **Failure Point**:

      * The NFT was **not** transferred to the auction winner's collection.
      * Instead, the NFT remains in the `SimpleScheduledMarketplace` contract's own internal `Collection` resource.

## 6\. Supporting Evidence: Testnet Event Logs

The following event logs were captured on the testnet for the transaction (`Tx ID: cf2050...`) that executed the scheduled `completeAuction` function. The logs confirm that the financial settlement code was executed, but the NFT transfer did not complete as expected.

```log
==============================
Checking event: BidPlaced
==============================
Events Block #281758524:
    Index         2
    Type          A.ac5b1841720e845a.SimpleScheduledMarketplace.BidPlaced
    Tx ID         8767c11ff4221af234737637fcd0b0b0e0ba492d9f062add27617289e271d048
    Values
                  - amount (UFix64): 25.00000000
                  - bidder (Address): 0xb1254feb278ff012
                  - itemID (UInt64): 3

==============================
Checking event: AuctionCompleted
==============================
Events Block #281758698:
    Index         21
    Type          A.ac5b1841720e845a.SimpleScheduledMarketplace.AuctionCompleted
    Tx ID         cf2050895575c0a0d8bab22e56cfe4a765bb65f10743beeb7f4000e49d254fc3
    Values
                  - finalPrice (UFix64): 25.00000000
                  - itemID (UInt64): 3
                  - winner ((Address)?): 0xb1254feb278ff012

==============================
(Custom Debugging Events from the Same Transaction)
==============================
Block #281758698, Tx ID: cf2050...

- Randomevent:  "1. winnningVault balance: 25.00000000"
- Randomevent2: "2. fee: 6.25000000"
- Randomevent3: "3. sellerAmount: 18.75000000"
- Randomevent4: "4. ownerReceiver: 0xac5b1841720e845a"
- Randomevent5: "5. sellerReceiver: 0x5542f6363675f0cd"
- Randomevent6: "Deposited fee of 6.25000000 to owner 0xac5b1841720e845a"
- Randomevent7: "Deposited 18.75000000 to seller 0x5542f6363675f0cd"
- Randomevent8: "Withdrew NFT ID 3 from saleCollection"
- Randomevent9: "Winner is 0xb1254feb278ff012"
- Randomevent10: "Depositing NFT to winner's collection"
```

### 6.1. Log Analysis

  * The `Randomevent8` log confirms the NFT was successfully withdrawn from the marketplace's internal storage (`saleCollection`).
  * The `Randomevent10` log indicates the code path to deposit the NFT into the winner's collection was reached.
  * The conspicuous absence of a standard `A.CoreContracts.NonFungibleToken.Deposit` event suggests that the `deposit()` call failed silently or was reverted without causing the entire transaction to fail. This is a common symptom of a missing or misconfigured `Receiver` capability or a full/non-existent storage path on the recipient's account.

## 7\. Visual Confirmation

Attached are screenshots from the Flow Testnet block explorer showing the NFT (ID: `3`) still residing in the marketplace contract's collection (`0xac5b1841720e845a`) after the auction's conclusion.

<img width="2429" height="1264" alt="image" src="https://github.com/user-attachments/assets/0cfb3780-c44e-47a5-a8e1-9b4489f8a730" />


## 7\. Conclusion

The evidence strongly suggests an issue related to account storage, capabilities, or permissions that is unique to the testnet environment. The discrepancy between the emulator and testnet indicates that the assumptions about the winner's account setup (i.e., the existence and accessibility of their NFT `Collection` resource) are not holding true in the testnet's more restrictive, multi-account environment. Further investigation should focus on the capability acquisition and the `deposit` operation within the `completeAuction` function.
