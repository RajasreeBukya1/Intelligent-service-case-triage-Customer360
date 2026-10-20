public with sharing class CaseTriageService {
    public class TriageResult {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String intent;
        @AuraEnabled public Integer urgencyScore;
        @AuraEnabled public String recommendedPriority;
        @AuraEnabled public String recommendedQueue;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String reason;
        @AuraEnabled public Customer360Service.Customer360Context customer360;
        @AuraEnabled public List<String> recommendations;
    }

    public static TriageResult triage(Id caseId, Boolean persist) {
        if (caseId == null) throw new AuraHandledException('Case Id is required.');
        Case c = [SELECT Id, Subject, Description, Priority, Status, Origin, AccountId,
                         Account.Name, Account.Industry, Account.Type
                  FROM Case WHERE Id = :caseId LIMIT 1];

        String text = ((c.Subject == null ? '' : c.Subject) + ' ' +
                       (c.Description == null ? '' : c.Description)).toLowerCase();
        String intent = classifyIntent(text);
        Integer score = calculateUrgency(c, text);
        String priority = score >= 80 ? 'Critical' : score >= 60 ? 'High' : score >= 30 ? 'Medium' : 'Low';
        String queue = queueForIntent(intent);
        Decimal confidence = confidenceForIntent(text, intent);

        TriageResult result = new TriageResult();
        result.caseId = c.Id;
        result.intent = intent;
        result.urgencyScore = score;
        result.recommendedPriority = priority;
        result.recommendedQueue = queue;
        result.confidence = confidence;
        result.reason = buildReason(c, intent, score, priority);
        result.customer360 = Customer360Service.getContext(c.AccountId);
        result.recommendations = buildRecommendations(intent, priority, result.customer360);

        if (persist) persistResult(result);
        return result;
    }

    private static String classifyIntent(String text) {
        if (containsAny(text, new List<String>{'fraud', 'unauthorized', 'stolen', 'scam'})) return 'Fraud';
        if (containsAny(text, new List<String>{'payment', 'charge', 'charged', 'invoice', 'billing', 'fee'})) return 'Billing';
        if (containsAny(text, new List<String>{'login', 'password', 'error', 'not working', 'system', 'technical', 'outage'})) return 'Technical';
        if (containsAny(text, new List<String>{'cancel', 'close account', 'complaint', 'angry', 'unhappy'})) return 'Complaint';
        if (containsAny(text, new List<String>{'address', 'phone', 'email', 'profile', 'account information'})) return 'Account';
        return 'General';
    }

    private static Integer calculateUrgency(Case c, String text) {
        Integer score = 10;
        if (containsAny(text, new List<String>{'fraud', 'unauthorized', 'stolen'})) score += 55;
        if (containsAny(text, new List<String>{'outage', 'blocked', 'cannot access', 'urgent'})) score += 25;
        if (containsAny(text, new List<String>{'angry', 'complaint', 'lawyer', 'regulator'})) score += 20;
        if (c.Priority == 'High') score += 20;
        if (c.Priority == 'Medium') score += 10;
        if (c.Status == 'Escalated') score += 20;
        return Math.min(score, 100);
    }

    private static String queueForIntent(String intent) {
        Map<String, String> queues = new Map<String, String>{
            'Fraud' => 'Fraud Operations', 'Billing' => 'Billing Support',
            'Technical' => 'Technical Support', 'Complaint' => 'Escalations',
            'Account' => 'Account Services', 'General' => 'General Support'
        };
        return queues.get(intent);
    }

    private static Decimal confidenceForIntent(String text, String intent) {
        if (intent == 'General') return 0.55;
        Integer hits = 0;
        if (intent == 'Fraud' && containsAny(text, new List<String>{'fraud','unauthorized','stolen','scam'})) hits++;
        if (intent == 'Billing' && containsAny(text, new List<String>{'payment','charge','invoice','billing'})) hits++;
        if (intent == 'Technical' && containsAny(text, new List<String>{'login','error','technical','outage'})) hits++;
        if (intent == 'Complaint' && containsAny(text, new List<String>{'cancel','complaint','angry','unhappy'})) hits++;
        if (intent == 'Account' && containsAny(text, new List<String>{'address','phone','email','profile'})) hits++;
        return hits > 0 ? 0.90 : 0.70;
    }

    private static String buildReason(Case c, String intent, Integer score, String priority) {
        return 'Detected ' + intent + ' intent. Urgency score=' + score + '/100. ' +
               'Recommended priority=' + priority + '. Case origin=' + c.Origin + '.';
    }

    private static List<String> buildRecommendations(String intent, String priority, Customer360Service.Customer360Context ctx) {
        List<String> out = new List<String>();
        if (intent == 'Fraud') out.add('Verify customer identity and route to Fraud Operations.');
        else if (intent == 'Billing') out.add('Review recent charges and billing history before responding.');
        else if (intent == 'Technical') out.add('Check known incidents and reproduce the issue before escalation.');
        else if (intent == 'Complaint') out.add('Acknowledge the customer concern and review prior escalations.');
        else out.add('Review Customer 360 context and confirm the customer request.');
        if (ctx != null && ctx.openCaseCount > 2) out.add('Review open cases to avoid duplicate troubleshooting.');
        if (ctx != null && ctx.churnRisk != null && ctx.churnRisk >= 0.70) out.add('Use retention-aware communication and consider an escalation.');
        if (priority == 'Critical') out.add('Follow critical-case SLA and notify the appropriate lead.');
        return out;
    }

    private static void persistResult(TriageResult result) {
        Case_Triage__c triage = new Case_Triage__c(
            Case__c = result.caseId, Intent__c = result.intent,
            Urgency_Score__c = result.urgencyScore,
            Recommended_Priority__c = result.recommendedPriority,
            Recommended_Queue__c = result.recommendedQueue,
            Confidence__c = result.confidence,
            Reason__c = result.reason,
            Customer_360_Summary__c = Customer360Service.toSummary(result.customer360)
        );
        insert triage;
        List<Case_Recommendation__c> recs = new List<Case_Recommendation__c>();
        Integer rank = 1;
        for (String rec : result.recommendations) {
            recs.add(new Case_Recommendation__c(Case__c=result.caseId, Triage__c=triage.Id,
                Recommendation__c=rec, Action_Type__c='Triage', Rank__c=rank++));
        }
        if (!recs.isEmpty()) insert recs;
    }

    private static Boolean containsAny(String text, List<String> words) {
        for (String word : words) if (text.contains(word)) return true;
        return false;
    }
}
