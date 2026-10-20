Case c = [SELECT Id, Subject FROM Case WHERE Subject = 'Unauthorized payment' ORDER BY CreatedDate DESC LIMIT 1];
CaseTriageService.TriageResult r = CaseTriageService.triage(c.Id, true);
System.debug(JSON.serializePretty(r));
