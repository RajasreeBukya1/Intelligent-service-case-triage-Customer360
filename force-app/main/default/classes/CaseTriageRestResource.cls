@RestResource(urlMapping='/intelligent-triage/v1/cases/*')
global with sharing class CaseTriageRestResource {
    global class ResponseBody {
        public Id caseId;
        public String intent;
        public Integer urgencyScore;
        public String priority;
        public String queue;
        public Decimal confidence;
        public String reason;
        public String customer360;
    }

    @HttpGet
    global static ResponseBody getTriage() {
        RestRequest req = RestContext.request;
        String caseId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        CaseTriageService.TriageResult r = CaseTriageService.triage((Id)caseId, false);
        ResponseBody out = new ResponseBody();
        out.caseId=r.caseId; out.intent=r.intent; out.urgencyScore=r.urgencyScore;
        out.priority=r.recommendedPriority; out.queue=r.recommendedQueue;
        out.confidence=r.confidence; out.reason=r.reason;
        out.customer360=Customer360Service.toSummary(r.customer360);
        return out;
    }
}
