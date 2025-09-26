import FlowTransactionScheduler from  0x8c5303eaa26202d6
import SimpleScheduledMarketplace from 0xac5b1841720e845a 

access(all) contract ScheduleCallbackHandler {

    access(all) struct loradata{
        access(all) let listingId: UInt64

        init(listingId: UInt64) {
            self.listingId = listingId
        }
    }

    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {


        access(FlowTransactionScheduler.Execute) fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let data = data as! loradata
            let listingID = data.listingId
            if listingID == nil {
                log("ScheduleCallbackHandler.executeCallback: no listingID provided in callback data. callback id: ".concat(id.toString()))
                return
            }

            SimpleScheduledMarketplace.completeAuction(listingID: listingID!)
            log("ScheduleCallbackHandler.executeCallback: completed auction for listing ".concat(listingID!.toString()).concat(" callback id: ").concat(id.toString()))
        }
    }

    access(all) fun createHandler(): @Handler {
        return <- create Handler()
    }
}
