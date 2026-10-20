public with sharing class CaseTriageQueueable implements Queueable {
    private Set<Id> caseIds;
    public CaseTriageQueueable(Set<Id> caseIds) { this.caseIds = caseIds == null ? new Set<Id>() : caseIds; }
    public void execute(QueueableContext context) {
        for (Id caseId : caseIds) CaseTriageService.triage(caseId, true);
    }
}
