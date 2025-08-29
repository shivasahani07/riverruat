import { LightningElement, track, wire, api } from 'lwc';
import getActivatedClaims from '@salesforce/apex/PackingSlipCompController.getActivatedClaims';
import { NavigationMixin } from "lightning/navigation";

export default class PackingSlipLwcComp extends NavigationMixin(LightningElement) {

    claimColumns = [
        { label: 'Claim Name', fieldName: 'Name', cellAttributes: { alignment: 'left' } },
        { label: 'Total Claim Amount', fieldName: 'Total_Claim_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' } }
    ];

    selectedClaimsColumns = [
        { label: 'Claim Name', fieldName: 'Name' },
        { label: 'Total Claim Amount', fieldName: 'Total_Claim_Amount__c', type: 'currency', cellAttributes: { alignment: 'left' } },
        {
            type: 'button',
            label: 'Remove',
            typeAttributes: {
                name: 'remove',
                label: 'Remove',
                variant: 'destructive'
            }
        }
    ];

    @track activatedClaims = [];
    @track allClaims = [];
    @track error;
    @track showModal = false;
    @track selectedClaims = [];
    @api recordId;

    @wire(getActivatedClaims, { batchId: '$recordId' })
    wiredClaims(result) {
        this.wiredClaimsResult = result;

        if (result.data) {
            this.claims = result.data;
            this.activatedClaims = result.data;
        }
        else if (result.error) {
            console.log('ERROR :  ' + error);
        }
    }

    handleActivatedClaims() {
        this.showModal = true;

        // Filter out already selected claims
        const selectedIds = new Set(this.selectedClaims.map(claim => claim.Id));

        this.allClaims = this.activatedClaims.filter(
            claim => !selectedIds.has(claim.Id)
        );
    }

    handleRowSelection(event) {
        const newSelections = event.detail.selectedRows;   // c1
        console.log('newSelctions : ' + JSON.stringify(newSelections));

        const allSelectionsMap = new Map();

        this.selectedClaims.forEach(claim => allSelectionsMap.set(claim.Id, claim));

        newSelections.forEach(claim => allSelectionsMap.set(claim.Id, claim));

        this.selectedClaims = Array.from(allSelectionsMap.values());

        console.log('Updated Selected Claims: ', JSON.stringify(this.selectedClaims));
    }

    handleSelect() {
        this.showModal = false;
    }

    resetForm() {
        //this.selectedClaims = [];
        this.showModal = false;
    }

    handleRowActionRemove(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'remove') {
            this.selectedClaims = this.selectedClaims.filter(
                claim => claim.Id !== row.Id
            );
        }
    }

    handleModalClose() {
        this.showModal = false;
    }

    closeComponent(event) {
        this.handleNavigation(this.recordId, 'Create_Batch__c', 'view');
    }

    handleNavigation(recordId, objectApiName = 'Create_Batch__c', actionName = 'view') {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: actionName
            }
        });
    }

}