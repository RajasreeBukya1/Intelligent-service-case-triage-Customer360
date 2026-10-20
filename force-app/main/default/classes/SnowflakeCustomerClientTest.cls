@IsTest
private class SnowflakeCustomerClientTest {
    private class CustomerMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().contains('callout:Customer360_Snowflake/api/customer/CUST-1001'));
            HttpResponse res = new HttpResponse(); res.setStatusCode(200); res.setHeader('Content-Type','application/json');
            res.setBody('{"externalCustomerId":"CUST-1001","lifetimeValue":12345.67,"openCaseCount":2,"recentOrderCount":4,"churnRisk":0.33,"preferredChannel":"Email","unifiedProfileId":"UP-1001"}');
            return res;
        }
    }
    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) { HttpResponse res=new HttpResponse(); res.setStatusCode(503); res.setBody('Service unavailable'); return res; }
    }
    @IsTest static void parsesCustomerResponse() {
        Test.setMock(HttpCalloutMock.class, new CustomerMock());
        Test.startTest(); SnowflakeCustomerClient.CustomerResponse c=SnowflakeCustomerClient.getCustomer('CUST-1001'); Test.stopTest();
        System.assertEquals(Decimal.valueOf('12345.67'), c.lifetimeValue);
        System.assertEquals(2, c.openCaseCount);
        System.assertEquals('UP-1001', c.unifiedProfileId);
    }
    @IsTest static void handlesHttpError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        try { SnowflakeCustomerClient.getCustomer('CUST-ERROR'); System.assert(false); }
        catch (AuraHandledException e) { System.assert(e.getMessage().contains('503')); }
    }
}
