@isTest
public class ApplicationRequirementTriggerTest {
    @isTest
    static void testApplicationRequirementCreation() {
        // 1. Create a test Account (Applied Program)
        Account testProgram = new Account(Name = 'Undergraduate');
        insert testProgram;

        // 2. Create a test Contact (Applicant) with Nationality
        Contact testApplicant = new Contact(
            LastName = 'Tester', 
            FirstName = 'Admin',
            Nationality__c = 'Malaysian' // This triggers the 'Domestic' logic
        );
        insert testApplicant;

        // 3. Create the test Application
        Application__c testApp = new Application__c(
            Applicant__c = testApplicant.Id,        
            Applied_Program__c = testProgram.Id,     
            Application_Status__c = 'Submitted'
        );

        // 4. Insert record to fire the trigger
        Test.startTest();
        insert testApp;
        Test.stopTest();

        // 5. Verify that Application Requirements were created
        List<Application_Requirement__c> createdReqs = [SELECT Id, Name 
                                                        FROM Application_Requirement__c 
                                                        WHERE Application__c = :testApp.Id];
        
        System.assert(createdReqs.size() > 0, 'Trigger failed to create requirements by looking up Contact nationality.');
    }
}