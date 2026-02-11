trigger ApplicationRequirementTrigger on Application__c (after insert) {
    List<Application_Requirement__c> reqsToCreate = new List<Application_Requirement__c>();
    Set<Id> contactIds = new Set<Id>();

    // Step 1: Collect Contact IDs to fetch nationalities
    for (Application__c app : Trigger.new) {
        if (app.Applicant__c != null) {
            contactIds.add(app.Applicant__c);
        }
    }

    // Step 2: Query Contact nationalities
    Map<Id, Contact> applicantMap = new Map<Id, Contact>([
        SELECT Id, Nationality__c FROM Contact WHERE Id IN :contactIds
    ]);

    // Step 3: Fetch all Program Requirements Metadata for both types to avoid SOQL in loop
    List<Program_Requirement__mdt> allMetadata = [SELECT MasterLabel, Domestic__c FROM Program_Requirement__mdt];

    for (Application__c app : Trigger.new) {
        // Step 4: Determine Nationality from Application or related Contact
        String nationality = app.Nationality__c;
        if (String.isBlank(nationality) && applicantMap.containsKey(app.Applicant__c)) {
            nationality = applicantMap.get(app.Applicant__c).Nationality__c;
        }

        // Step 5: Map Nationality to Category logic
        String category = (nationality != null && nationality.equalsIgnoreCase('Malaysian')) 
                          ? 'Domestic' 
                          : 'International';

        // Step 6: Create records matching the determined category
        for (Program_Requirement__mdt mdt : allMetadata) {
            if (mdt.Domestic__c == category) {
                Application_Requirement__c newReq = new Application_Requirement__c();
                newReq.Name = mdt.MasterLabel;
                newReq.Application__c = app.Id; 
                newReq.Requirement_Type__c = mdt.Domestic__c; 
                reqsToCreate.add(newReq);
            }
        }
    }

    if (!reqsToCreate.isEmpty()) {
        insert reqsToCreate;
    }
}