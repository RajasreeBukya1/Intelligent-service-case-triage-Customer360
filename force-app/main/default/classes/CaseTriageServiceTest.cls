@IsTest
private class CaseTriageServiceTest {
    @TestSetup static void setupData() {
        Account a = new Account(Name='Acme Banking Customer');
        insert a;
        insert new Customer_360_Profile__c(Account__c=a.Id, External_Customer_Id__c='CUST-1001',
            Lifetime_Value__c=125000, Open_Case_Count__c=3, Recent_Order_Count__c=8,
            Churn_Risk__c=0.82, Preferred_Channel__c='Phone', Unified_Profile_Id__c='UP-1001', Data_Source__c='Data 360');
        insert new Case(AccountId=a.Id, Subject='Unauthorized payment on my account',
            Description='I see a charge I did not make. Please block it urgently.', Origin='Phone', Priority='High', Status='New');
    }

    @IsTest static void classifiesFraudAndPersistsRecommendations() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        CaseTriageService.TriageResult result = CaseTriageService.triage(c.Id, true);
        Test.stopTest();
        System.assertEquals('Fraud', result.intent);
        System.assertEquals('Critical', result.recommendedPriority);
        System.assertEquals('Fraud Operations', result.recommendedQueue);
        System.assert(result.urgencyScore >= 80);
        System.assertEquals(1, [SELECT COUNT() FROM Case_Triage__c WHERE Case__c=:c.Id]);
        System.assert([SELECT COUNT() FROM Case_Recommendation__c WHERE Case__c=:c.Id] > 0);
    }

    @IsTest static void defaultsToGeneral() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Case c = new Case(AccountId=a.Id, Subject='Question about my service', Description='Can you explain my account?', Origin='Web');
        insert c;
        CaseTriageService.TriageResult result = CaseTriageService.triage(c.Id, false);
        System.assertEquals('General', result.intent);
        System.assertEquals('Low', result.recommendedPriority);
        System.assertEquals(0.55, result.confidence);
    }
}
