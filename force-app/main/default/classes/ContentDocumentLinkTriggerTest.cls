@isTest
public class ContentDocumentLinkTriggerTest {

    @testSetup
    static void setupData() {
        // 1. Create Account and Contact for the Applicant
        Account testProgram = new Account(Name = 'Undergraduate');
        insert testProgram;

        Contact testApplicant = new Contact(
            LastName = 'Tester',
            Nationality__c = 'Malaysian'
        );
        insert testApplicant;

        // 2. Create the Application
        Application__c testApp = new Application__c(
            Applicant__c = testApplicant.Id,
            Applied_Program__c = testProgram.Id,
            Application_Status__c = 'Submitted'
        );
        insert testApp;

        // 3. Create the Application Requirement (The Trigger will likely create this, but we create one for explicit testing)
        Application_Requirement__c testReq = new Application_Requirement__c(
            Name = 'Transcript',
            Application__c = testApp.Id,
            Requirement_Type__c = 'Domestic'
        );
        insert testReq;
    }

    @isTest
    static void testFileSyncToApplication() {
        // Fetch the Requirement and Parent Application
        Application_Requirement__c req = [SELECT Id, Application__c FROM Application_Requirement__c LIMIT 1];
        
        // 4. Create a File (ContentVersion)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        // Fetch the ContentDocumentId created automatically by Salesforce
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // 5. Link the File to the Requirement
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = req.Id,
            ShareType = 'V'
        );

        Test.startTest();
        insert cdl; // This fires your ContentDocumentLinkTrigger
        Test.stopTest();

        // 6. Verify the file is now linked to BOTH the Requirement and the Application
        List<ContentDocumentLink> links = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :docId];
        
        Set<Id> linkedIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            linkedIds.add(link.LinkedEntityId);
        }

        System.assert(linkedIds.contains(req.Id), 'File should be linked to the Requirement.');
        System.assert(linkedIds.contains(req.Application__c), 'File should be automatically linked to the Parent Application.');
    }
}