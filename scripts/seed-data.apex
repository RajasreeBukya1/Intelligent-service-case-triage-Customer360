Account a = new Account(Name='Demo Financial Customer');
insert a;
insert new Customer_360_Profile__c(
    Account__c=a.Id,
    External_Customer_Id__c='CUST-DEMO-001',
    Lifetime_Value__c=95000,
    Open_Case_Count__c=2,
    Recent_Order_Count__c=6,
    Churn_Risk__c=0.72,
    Preferred_Channel__c='Phone',
    Unified_Profile_Id__c='UP-DEMO-001',
    Data_Source__c='Data 360'
);
insert new Case(AccountId=a.Id, Subject='Unauthorized payment', Description='Customer reports a payment they do not recognize and wants immediate help.', Origin='Phone', Priority='High', Status='New');
System.debug('Created demo account and case.');
