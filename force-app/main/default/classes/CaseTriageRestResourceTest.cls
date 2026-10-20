@IsTest
private class CaseTriageRestResourceTest {
    @IsTest static void returnsTriageOverRest() {
        Account a = new Account(Name='REST Customer'); insert a;
        Case c = new Case(AccountId=a.Id, Subject='Billing charge question', Description='Why was I charged this fee?', Origin='Web'); insert c;
        RestRequest req = new RestRequest(); req.requestURI='/services/apexrest/intelligent-triage/v1/cases/'+c.Id; req.httpMethod='GET';
        RestContext.request=req; RestContext.response=new RestResponse();
        Test.startTest(); CaseTriageRestResource.ResponseBody body=CaseTriageRestResource.getTriage(); Test.stopTest();
        System.assertEquals(c.Id, body.caseId); System.assertEquals('Billing', body.intent); System.assertEquals('Billing Support', body.queue);
    }
}
