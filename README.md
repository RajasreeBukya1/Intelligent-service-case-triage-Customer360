# Intelligent Service Case Triage & Customer 360

An end-to-end service architecture using **Service Cloud, Apex, LWC, Salesforce Flow, REST callouts/Named Credentials, Customer 360-style unified context, and Agentforce-ready Apex actions**.

> **Important:** This repository is a practice/reference implementation. The Data 360 and Agentforce setup steps require a Salesforce org with the appropriate licenses/features. The Apex project itself is designed to run in a normal Developer/Scratch org using mock integration responses.

## Business problem

Support agents receive cases with different channels, priorities, products and customer histories. The goal is to:

1. Classify case intent from case text.
2. Calculate a deterministic urgency score.
3. Recommend routing/priority and next-best actions.
4. Show a Customer 360 summary beside the case.
5. Enrich CRM data from an external customer-data source (represented by a Named Credential; Snowflake/Data 360 can be the real source).
6. Give Agentforce a governed action that returns triage recommendations.
7. Log the recommendation so the decision is auditable.

## Architecture

```text
                   +----------------------+
                   | Case / Service Cloud |
                   +----------+-----------+
                              |
                              v
                   +----------------------+
                   | CaseTriageService     |
                   | Apex domain/service   |
                   +----+-------------+----+
                        |             |
             +----------+             +----------------+
             v                                           v
     +----------------+                          +------------------+
     | Triage Engine  |                          | Customer 360     |
     | intent + score |                          | Context Service  |
     +-------+--------+                          +--------+---------+
             |                                            |
             v                                            v
     +----------------+                         Named Credential
     | Recommendation |                         REST endpoint
     | + audit record |                                  |
     +-------+--------+                                  v
             |                                  Snowflake / Data 360
             v
     +----------------+
     | LWC Agent UI   |
     | triage + 360   |
     +----------------+
             ^
             |
     +-----------------------+
     | Agentforce Invocable  |
     | Triage Action         |
     +-----------------------+
```

Salesforce's current documentation recommends Named Credentials for authenticated Apex callouts and supports Apex/Invocable methods as Agentforce actions. LWC can wire cacheable Apex methods and refresh Apex data when needed. See the official references linked in `docs/official-references.md`.

## Repo structure

```text
force-app/main/default/
  classes/
    CaseTriageService.cls
    CaseTriageService.cls-meta.xml
    CaseTriageController.cls
    CaseTriageController.cls-meta.xml
    Customer360Service.cls
    Customer360Service.cls-meta.xml
    SnowflakeCustomerClient.cls
    SnowflakeCustomerClient.cls-meta.xml
    AgentforceCaseTriageAction.cls
    AgentforceCaseTriageAction.cls-meta.xml
    CaseTriageServiceTest.cls
    CaseTriageServiceTest.cls-meta.xml
    Customer360ServiceTest.cls
    Customer360ServiceTest.cls-meta.xml
    SnowflakeCustomerClientTest.cls
    SnowflakeCustomerClientTest.cls-meta.xml
    AgentforceCaseTriageActionTest.cls
    AgentforceCaseTriageActionTest.cls-meta.xml
  lwc/
    caseTriage360/
  objects/
    Case_Triage__c/
    Customer_360_Profile__c/
    Case_Recommendation__c/
  permissionsets/
    Intelligent_Case_Triage.permissionset-meta.xml
scripts/
  seed-data.apex
  run-demo.apex
postman/
  customer360-demo.postman_collection.json
```

## 1. Create a Salesforce org

Use a Developer Edition, Trailhead Playground, or Scratch Org. If using a scratch org, make sure Service Cloud-compatible case functionality is available.

```bash
sf org login web --alias case-triage-dev
sf project deploy start --source-dir force-app --target-org case-triage-dev
```

Then assign the permission set:

```bash
sf org assign permset --name Intelligent_Case_Triage --target-org case-triage-dev
```

## 2. Create the integration credential

Create an **External Credential** and **Named Credential** in Setup. Use a named credential called:

`Customer360_Snowflake`

The Apex code intentionally uses:

`callout:Customer360_Snowflake`

Do not put OAuth client secrets or passwords into this repository. Current Salesforce guidance recommends the newer External Credential + Named Credential model instead of legacy named credentials.

For local practice without a real endpoint, use the included `HttpCalloutMock` tests. You can also point the Named Credential at a controlled mock API.

## 3. Data model

### Case_Triage__c

Audit record for the triage decision.

| Field | Type | Purpose |
|---|---|---|
| Case__c | Lookup(Case) | Source case |
| Intent__c | Picklist | Billing, Technical, Account, Complaint, General |
| Urgency_Score__c | Number | 0-100 deterministic score |
| Recommended_Priority__c | Picklist | Low, Medium, High, Critical |
| Recommended_Queue__c | Text | Routing recommendation |
| Reason__c | Long Text | Explainability |
| Customer_360_Summary__c | Long Text | Context used |
| Confidence__c | Percent | Confidence score |

### Customer_360_Profile__c

A CRM-side representation of unified customer context for practice. In a licensed Data 360 implementation, the authoritative unified profile would live in Data 360 and can be surfaced/activated into CRM.

| Field | Type |
|---|---|
| External_Customer_Id__c | Text |
| Account__c | Lookup(Account) |
| Lifetime_Value__c | Currency |
| Open_Case_Count__c | Number |
| Recent_Order_Count__c | Number |
| Churn_Risk__c | Percent |
| Preferred_Channel__c | Text |
| Data_Source__c | Text |
| Unified_Profile_Id__c | Text |

### Case_Recommendation__c

Stores recommended next actions.

| Field | Type |
|---|---|
| Case__c | Lookup(Case) |
| Triage__c | Lookup(Case_Triage__c) |
| Recommendation__c | Text |
| Action_Type__c | Picklist |
| Rank__c | Number |
| Completed__c | Checkbox |

## 4. Main flow

When a support user opens a case:

1. LWC calls `CaseTriageController.getCaseWorkspace(caseId)`.
2. Apex reads Case + Account context.
3. `CaseTriageService.triage()` normalizes the case text.
4. Intent rules classify the case.
5. Urgency score is calculated using severity, SLA risk, sentiment words, and customer risk.
6. `Customer360Service` retrieves CRM-side Customer 360 data.
7. `SnowflakeCustomerClient` can enrich the profile from an external API.
8. The service persists `Case_Triage__c` and `Case_Recommendation__c` records.
9. LWC displays the recommendation, score, Customer 360 metrics, and next actions.
10. Agentforce can call the same governed triage service through `AgentforceCaseTriageAction`.

## 5. Data 360 implementation path

The repository intentionally does **not** fake Data 360 metadata because Data 360 configuration is tenant/license dependent. In a real org:

- Ingest CRM, ERP/order, web/app and support data.
- Map source data to Data 360 Data Model Objects.
- Configure identity resolution to create unified customer profiles.
- Create a calculated insight such as `Customer_Health_Score`.
- Activate/retrieve unified context into the service experience.
- Use the unified profile as grounding/context for service recommendations.

Salesforce's Data 360 architecture describes ingestion, harmonization, identity resolution and activation as the core pattern for unified customer data.

## 6. Agentforce implementation path

Create an Agentforce action from the Apex invocable method:

`AgentforceCaseTriageAction.triage`

Suggested agent instructions:

```text
You are a customer service triage assistant.

When a user asks to triage a case:
1. Use the Case ID if supplied.
2. Call the case triage action.
3. Present intent, urgency, recommended priority, queue and reason.
4. Show the Customer 360 context used by the recommendation.
5. Do not invent customer information.
6. If the action reports missing data, clearly state that the data is unavailable.
7. Never close a case, refund money, change account ownership, or perform another high-impact action without an explicit human confirmation and an appropriate downstream action.
```

Agentforce supports custom actions built from Apex controller/Invocable methods and REST classes. This project uses an Invocable method so the business logic remains reusable and testable.



