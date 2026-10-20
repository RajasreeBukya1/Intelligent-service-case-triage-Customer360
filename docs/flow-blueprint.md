# Salesforce Flow Blueprint

The deployable Apex code is intentionally separated from the Flow configuration because Flow metadata is often easier to learn by building in Flow Builder.

## Flow: Case - Intelligent Triage

**Type:** Record-Triggered Flow

**Object:** Case

**Trigger:** When a record is created or updated

**Entry condition:**
- Status != Closed
- Subject Is Changed = True OR Description Is Changed = True OR Is New = True

**Elements:**

1. **Get Case / related Account**
   - Case Id = `$Record.Id`
   - AccountId = `$Record.AccountId`

2. **Action — Apex: Intelligent Case Triage**
   - Select `AgentforceCaseTriageAction.triage`
   - Pass `$Record.Id` to `caseId`

3. **Decision — Critical?**
   - If urgency score >= 80 → high-priority branch
   - Otherwise → normal branch

4. **Update Records** (optional, human-governed)
   - Update Case Priority only if business policy allows automated priority updates.
   - Do not automatically close, refund, or take other irreversible actions.

5. **Create Task** (optional)
   - Create follow-up task for critical cases.

6. **Fault path**
   - Create an Integration/Automation Log record.
   - Include Case Id, Flow name, error message and timestamp.

