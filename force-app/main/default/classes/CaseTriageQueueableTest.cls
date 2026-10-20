@IsTest
private class CaseTriageQueueableTest {
    @IsTest static void queuesTriage() {
        Account a=new Account(Name='Queue Customer'); insert a;
        Case c=new Case(AccountId=a.Id, Subject='Technical error', Description='System error when logging in', Origin='Web'); insert c;
        Test.startTest(); System.enqueueJob(new CaseTriageQueueable(new Set<Id>{c.Id})); Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Case_Triage__c WHERE Case__c=:c.Id]);
    }
}
