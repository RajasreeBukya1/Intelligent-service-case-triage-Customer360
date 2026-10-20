public with sharing class Customer360Service {
    public class Customer360Context {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal lifetimeValue;
        @AuraEnabled public Integer openCaseCount;
        @AuraEnabled public Integer recentOrderCount;
        @AuraEnabled public Decimal churnRisk;
        @AuraEnabled public String preferredChannel;
        @AuraEnabled public String unifiedProfileId;
        @AuraEnabled public String source;
    }

    public static Customer360Context getContext(Id accountId) {
        Customer360Context ctx = new Customer360Context();
        ctx.accountId = accountId;
        if (accountId == null) return ctx;
        Account a = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
        ctx.accountName = a.Name;
        List<Customer_360_Profile__c> profiles = [
            SELECT Lifetime_Value__c, Open_Case_Count__c, Recent_Order_Count__c,
                   Churn_Risk__c, Preferred_Channel__c, Unified_Profile_Id__c, Data_Source__c
            FROM Customer_360_Profile__c WHERE Account__c = :accountId ORDER BY LastModifiedDate DESC LIMIT 1
        ];
        if (!profiles.isEmpty()) {
            Customer_360_Profile__c p = profiles[0];
            ctx.lifetimeValue = p.Lifetime_Value__c;
            ctx.openCaseCount = p.Open_Case_Count__c == null ? 0 : Integer.valueOf(p.Open_Case_Count__c);
            ctx.recentOrderCount = p.Recent_Order_Count__c == null ? 0 : Integer.valueOf(p.Recent_Order_Count__c);
            ctx.churnRisk = p.Churn_Risk__c;
            ctx.preferredChannel = p.Preferred_Channel__c;
            ctx.unifiedProfileId = p.Unified_Profile_Id__c;
            ctx.source = p.Data_Source__c;
        } else {
            ctx.openCaseCount = [SELECT COUNT() FROM Case WHERE AccountId = :accountId AND IsClosed = false];
            ctx.source = 'CRM fallback';
        }
        return ctx;
    }

    public static String toSummary(Customer360Context c) {
        if (c == null) return 'No Customer 360 context available.';
        return 'Account=' + c.accountName + '; LTV=' + c.lifetimeValue + '; OpenCases=' + c.openCaseCount +
               '; RecentOrders=' + c.recentOrderCount + '; ChurnRisk=' + c.churnRisk +
               '; PreferredChannel=' + c.preferredChannel + '; Source=' + c.source;
    }
}
