trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
    Set<Id> requirementIds = new Set<Id>();

    // Step 1: Identify if the file is being uploaded to an Application Requirement
    for (ContentDocumentLink cdl : Trigger.new) {
        if (cdl.LinkedEntityId != null && 
            cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Application_Requirement__c') {
            requirementIds.add(cdl.LinkedEntityId);
        }
    }

    if (!requirementIds.isEmpty()) {
        // Step 2: Query for the Parent Application IDs
        Map<Id, Application_Requirement__c> reqMap = new Map<Id, Application_Requirement__c>([
            SELECT Id, Application__c FROM Application_Requirement__c WHERE Id IN :requirementIds
        ]);

        for (ContentDocumentLink cdl : Trigger.new) {
            if (requirementIds.contains(cdl.LinkedEntityId)) {
                Id parentAppId = reqMap.get(cdl.LinkedEntityId).Application__c;

                if (parentAppId != null) {
                    // Step 3: Create a new link for the parent Application
                    linksToCreate.add(new ContentDocumentLink(
                        ContentDocumentId = cdl.ContentDocumentId,
                        LinkedEntityId = parentAppId,
                        ShareType = 'V', // V = Viewer permission
                        Visibility = 'AllUsers'
                    ));
                }
            }
        }
    }

    // Step 4: Insert the new links (wrap in try-catch to ignore duplicates)
    if (!linksToCreate.isEmpty()) {
        Database.insert(linksToCreate, false);
    }
}