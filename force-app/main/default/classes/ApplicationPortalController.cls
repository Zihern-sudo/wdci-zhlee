public with sharing class ApplicationPortalController {
    
  @AuraEnabled(cacheable=true)
public static Contact getLoggedInContact() {
    User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    if (u.ContactId == null) return null;

    // Added Account.Name and AccountId to the query
    return [SELECT FirstName, LastName, Email, MobilePhone, Birthdate, Gender__c, Nationality__c,
                   AccountId, Account.Name 
            FROM Contact 
            WHERE Id = :u.ContactId LIMIT 1];
}

@AuraEnabled
public static String submitApplication(Map<String, Object> appData) {
    try {
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = currentUser.ContactId;

        // Fetch the ID directly from the data passed by the LWC
        String programId = (String)appData.get('appliedProgramId');

        Application__c newApp = new Application__c();
        newApp.Applicant__c = contactId; 
        newApp.Applied_Program__c = (Id)programId;
        newApp.High_School_Name__c = (String)appData.get('highSchoolName'); 
        newApp.Highest_Education_Level__c = (String)appData.get('highestEducationLevel');
        newApp.Source__c = (String)appData.get('source');
        newApp.Application_Status__c = 'Submitted';

        insert newApp;
        return newApp.Id;
    } catch (Exception e) {
        throw new AuraHandledException('Error: ' + e.getMessage());
    }
}

    @AuraEnabled(cacheable=true)
    public static String getUserNationality() {
        User u = [SELECT Contact.Nationality__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (u.Contact == null || String.isBlank(u.Contact.Nationality__c)) {
            return 'International';
        }
        return u.Contact.Nationality__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<Application__c> getMyApplications() {
        return [SELECT Name, CreatedDate, Application_Status__c, Applied_Program__r.Name 
                FROM Application__c 
                ORDER BY CreatedDate DESC];
    }
}