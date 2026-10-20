public with sharing class CaseTriageController {
    @AuraEnabled(cacheable=true)
    public static CaseTriageService.TriageResult getCaseWorkspace(Id caseId) {
        return CaseTriageService.triage(caseId, false);
    }

    @AuraEnabled
    public static CaseTriageService.TriageResult runTriage(Id caseId) {
        return CaseTriageService.triage(caseId, true);
    }
}
