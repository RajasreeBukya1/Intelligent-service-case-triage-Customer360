@IsTest
private class AgentforceCaseTriageActionTest {
    @IsTest static void returnsAgentResponse() {
        Account a = new Account(Name='Agent Customer'); insert a;
        insert new Customer_360_Profile__c(Account__c=a.Id, Lifetime_Value__c=80000, Open_Case_Count__c=1,
            Recent_Order_Count__c=3, Churn_Risk__c=0.10, Preferred_Channel__c='Chat', Data_Source__c='Data 360');
        Case c = new Case(AccountId=a.Id, Subject='Login error', Description='I cannot login to the portal', Origin='Web'); insert c;
        AgentforceCaseTriageAction.Request req = new AgentforceCaseTriageAction.Request(); req.caseId=c.Id;
        Test.startTest(); List<AgentforceCaseTriageAction.Response> out = AgentforceCaseTriageAction.triage(new List<AgentforceCaseTriageAction.Request>{req}); Test.stopTest();
        System.assertEquals(1, out.size());
        System.assertEquals('Technical', out[0].intent);
        System.assertEquals('Technical Support', out[0].recommendedQueue);
        System.assertNotEquals(null, out[0].customer360Summary);
    }
}
