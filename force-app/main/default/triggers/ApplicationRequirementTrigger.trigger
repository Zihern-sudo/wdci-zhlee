trigger ApplicationRequirementTrigger on Application__c (after insert, before update, after update) {
    
    // Step 1: Collect Contact IDs to fetch fresh Nationality data directly
    Set<Id> contactIds = new Set<Id>();
    for (Application__c app : Trigger.new) {
        if (app.Applicant__c != null) {
            contactIds.add(app.Applicant__c);
        }
    }

    // Step 2: Query the actual Contact data
    Map<Id, Contact> applicantMap = new Map<Id, Contact>([
        SELECT Id, Nationality__c FROM Contact WHERE Id IN :contactIds
    ]);

    // --- BEFORE UPDATE: Sync Nationality to Application Type ---
    if (Trigger.isBefore && Trigger.isUpdate) {
        for (Application__c app : Trigger.new) {
            Application__c oldApp = Trigger.oldMap.get(app.Id);
            String currentNat = applicantMap.get(app.Applicant__c)?.Nationality__c;
            
            // Sync Type if Nationality (on Contact) changed and Type was not manually overridden
            if (app.Application_Type__c == oldApp.Application_Type__c) {
                app.Application_Type__c = (currentNat != null && currentNat.equalsIgnoreCase('Malaysian')) 
                                          ? 'Domestic' : 'International';
            }
        }
    }

    // --- AFTER INSERT & AFTER UPDATE: Sync Requirements ---
    if (Trigger.isAfter) {
        List<Application_Requirement__c> reqsToCreate = new List<Application_Requirement__c>();
        Set<Id> appsToRefresh = new Set<Id>();

        for (Application__c app : Trigger.new) {
            if (Trigger.isInsert) {
                appsToRefresh.add(app.Id);
            } else if (Trigger.isUpdate) {
                // Refresh if the Application Type changed
                if (app.Application_Type__c != Trigger.oldMap.get(app.Id).Application_Type__c) {
                    appsToRefresh.add(app.Id);
                }
            }
        }

        if (!appsToRefresh.isEmpty()) {
            // Delete old requirements
            delete [SELECT Id FROM Application_Requirement__c WHERE Application__c IN :appsToRefresh];

            // Fetch correctly configured Metadata
            List<Program_Requirement__mdt> allMetadata = [SELECT MasterLabel, Domestic__c FROM Program_Requirement__mdt];

            for (Id appId : appsToRefresh) {
                Application__c currentApp = Trigger.newMap.get(appId);
                String typeToMatch = currentApp.Application_Type__c;

                // For initial insert, if Type is null, calculate it once more
                if (String.isBlank(typeToMatch)) {
                    String nat = applicantMap.get(currentApp.Applicant__c)?.Nationality__c;
                    typeToMatch = (nat != null && nat.equalsIgnoreCase('Malaysian')) ? 'Domestic' : 'International';
                }

                for (Program_Requirement__mdt mdt : allMetadata) {
                    if (mdt.Domestic__c == typeToMatch) {
                        reqsToCreate.add(new Application_Requirement__c(
                            Name = mdt.MasterLabel,
                            Application__c = appId,
                            Requirement_Type__c = mdt.Domestic__c
                        ));
                    }
                }
            }
        }

        if (!reqsToCreate.isEmpty()) {
            insert reqsToCreate;
        }
    }
}