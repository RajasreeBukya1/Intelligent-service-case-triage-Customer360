public with sharing class SnowflakeCustomerClient {
    public class CustomerResponse {
        public String externalCustomerId;
        public Decimal lifetimeValue;
        public Integer openCaseCount;
        public Integer recentOrderCount;
        public Decimal churnRisk;
        public String preferredChannel;
        public String unifiedProfileId;
    }

    public static CustomerResponse getCustomer(String externalCustomerId) {
        if (String.isBlank(externalCustomerId)) throw new AuraHandledException('External customer Id is required.');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Customer360_Snowflake/api/customer/' + EncodingUtil.urlEncode(externalCustomerId, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(10000);
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException('Customer data service returned HTTP ' + res.getStatusCode());
        }
        return (CustomerResponse) JSON.deserialize(res.getBody(), CustomerResponse.class);
    }
}
