public with sharing class AgentforceCaseTriageAction {
    public class Request {
        @InvocableVariable(required=true description='Salesforce Case Id to triage')
        public Id caseId;
    }
    public class Response {
        @InvocableVariable public String intent;
        @InvocableVariable public Integer urgencyScore;
        @InvocableVariable public String recommendedPriority;
        @InvocableVariable public String recommendedQueue;
        @InvocableVariable public Decimal confidence;
        @InvocableVariable public String reason;
        @InvocableVariable public String customer360Summary;
        @InvocableVariable public String recommendations;
    }

    @InvocableMethod(label='Intelligent Case Triage' description='Classifies a case, calculates urgency, and returns Customer 360-aware routing recommendations.')
    public static List<Response> triage(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request request : requests) {
            CaseTriageService.TriageResult r = CaseTriageService.triage(request.caseId, true);
            Response out = new Response();
            out.intent = r.intent;
            out.urgencyScore = r.urgencyScore;
            out.recommendedPriority = r.recommendedPriority;
            out.recommendedQueue = r.recommendedQueue;
            out.confidence = r.confidence;
            out.reason = r.reason;
            out.customer360Summary = Customer360Service.toSummary(r.customer360);
            out.recommendations = String.join(r.recommendations, ' | ');
            responses.add(out);
        }
        return responses;
    }
}
