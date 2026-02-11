public with sharing class ProgramRequirementController {
    @AuraEnabled(cacheable=true)
    public static List<Program_Requirement__mdt> getRequirements(String nationality) {
        if (String.isBlank(nationality)) {
            // Default to International if nothing is passed
            nationality = 'International';
        }

        String category;
        // Map the Contact's nationality to your Metadata picklist values
        if (nationality.equalsIgnoreCase('Malaysian')) {
            category = 'Domestic';
        } else {
            category = 'International';
        }
        
        return [SELECT MasterLabel, Domestic__c 
                FROM Program_Requirement__mdt 
                WHERE Domestic__c = :category 
                ORDER BY MasterLabel ASC];
    }
}