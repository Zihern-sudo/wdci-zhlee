@isTest
public class ApplicationRequirementTriggerTest {
    
    @testSetup
    static void setupData() {
        // Create the 'Undergraduate' Program Account
        Account testProgram = new Account(Name = 'Undergraduate');
        insert testProgram;

        // Create a test Contact with a valid Nationality
        Contact testApplicant = new Contact(
            LastName = 'Tester', 
            FirstName = 'Admin',
            Nationality__c = 'Malaysian' 
        );
        insert testApplicant;
    }

    @isTest
    static void testApplicationRequirementCreation() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c testApp = new Application__c(
            Applicant__c = con.Id,        
            Applied_Program__c = acc.Id,     
            Application_Status__c = 'Submitted'
        );

        Test.startTest();
        insert testApp; // Triggers requirement creation
        Test.stopTest();

        List<Application_Requirement__c> reqs = [SELECT Id, Requirement_Type__c FROM Application_Requirement__c WHERE Application__c = :testApp.Id];
        System.assert(reqs.size() > 0, 'Requirements should be created on insert.');
        System.assertEquals('Domestic', reqs[0].Requirement_Type__c);
    }

    @isTest
    static void testNationalityUpdateRefreshesRequirements() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c testApp = new Application__c(
            Applicant__c = con.Id,
            Applied_Program__c = acc.Id
        );
        insert testApp;

        // Change Nationality on Contact record
        Test.startTest();
        con.Nationality__c = 'Singaporean'; 
        update con;
        
        // Update the Application to fire the 'before/after update' trigger logic
        update testApp; 
        Test.stopTest();

        List<Application_Requirement__c> updatedReqs = [SELECT Id, Requirement_Type__c FROM Application_Requirement__c WHERE Application__c = :testApp.Id];
        
        // Assert that new International records exist based on metadata
        System.assert(!updatedReqs.isEmpty(), 'International requirements should be found in Metadata.');
        System.assertEquals('International', updatedReqs[0].Requirement_Type__c);
    }

    @isTest
    static void testOfficerManualTypeOverride() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c testApp = new Application__c(
            Applicant__c = con.Id,
            Applied_Program__c = acc.Id
        );
        insert testApp;

        // Simulate an Admission Officer manually changing the Type
        Test.startTest();
        testApp.Application_Type__c = 'International';
        update testApp;
        Test.stopTest();

        List<Application_Requirement__c> manualReqs = [SELECT Id, Requirement_Type__c FROM Application_Requirement__c WHERE Application__c = :testApp.Id];
        System.assert(!manualReqs.isEmpty(), 'Manual override should trigger new requirements.');
        System.assertEquals('International', manualReqs[0].Requirement_Type__c);
    }
}