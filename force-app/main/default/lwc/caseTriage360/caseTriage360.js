import { LightningElement, api, wire } from 'lwc';
import getCaseWorkspace from '@salesforce/apex/CaseTriageController.getCaseWorkspace';
import runTriage from '@salesforce/apex/CaseTriageController.runTriage';
import { refreshApex } from '@salesforce/apex';

export default class CaseTriage360 extends LightningElement {
    @api recordId;
    result;
    errorMessage;
    loading = false;
    wiredResult;

    @wire(getCaseWorkspace, { caseId: '$recordId' })
    wiredCase(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) { this.result = data; this.errorMessage = undefined; }
        if (error) { this.errorMessage = this.reduceError(error); }
    }

    get confidencePercent() {
        return this.result?.confidence != null ? Math.round(this.result.confidence * 100) : 0;
    }

    get churnRiskPercent() {
        return this.result?.customer360?.churnRisk != null ? Math.round(this.result.customer360.churnRisk * 100) : 0;
    }

    async handleRun() {
        this.loading = true;
        this.errorMessage = undefined;
        try {
            this.result = await runTriage({ caseId: this.recordId });
            await refreshApex(this.wiredResult);
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        } finally {
            this.loading = false;
        }
    }

    async handleRefresh() {
        this.loading = true;
        try { await refreshApex(this.wiredResult); }
        catch (e) { this.errorMessage = this.reduceError(e); }
        finally { this.loading = false; }
    }

    reduceError(error) {
        return error?.body?.message || error?.message || 'Unexpected error';
    }
}
