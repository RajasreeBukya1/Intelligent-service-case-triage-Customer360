@IsTest
private class Customer360ServiceTest {
    @IsTest static void returnsProfileContext() {
        Account a = new Account(Name='Customer 360 Test'); insert a;
        insert new Customer_360_Profile__c(Account__c=a.Id, Lifetime_Value__c=50000, Open_Case_Count__c=2,
            Recent_Order_Count__c=5, Churn_Risk__c=0.25, Preferred_Channel__c='Email',
            Unified_Profile_Id__c='UP-1', Data_Source__c='Data 360');
        Customer360Service.Customer360Context ctx = Customer360Service.getContext(a.Id);
        System.assertEquals('Customer 360 Test', ctx.accountName);
        System.assertEquals(Decimal.valueOf('50000'), ctx.lifetimeValue);
        System.assertEquals(2, ctx.openCaseCount);
        System.assertEquals('Email', ctx.preferredChannel);
    }

    @IsTest static void fallsBackToOpenCaseCount() {
        Account a = new Account(Name='Fallback Test'); insert a;
        insert new Case(AccountId=a.Id, Subject='Open issue', Status='New', Origin='Email');
        Customer360Service.Customer360Context ctx = Customer360Service.getContext(a.Id);
        System.assertEquals(1, ctx.openCaseCount);
        System.assertEquals('CRM fallback', ctx.source);
    }
}
