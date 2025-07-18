import { LightningElement, track } from 'lwc';
import createMultipleTFRs from '@salesforce/apex/TFRController.createMultipleTFRs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TfrCreatorNew extends LightningElement {
    @track tfrList = [];
    @track isLoading = false;

    connectedCallback() {
        this.addTFR(); // Start with 1 TFR
    }

    addTFR() {
        this.tfrList.push({
            VIN_Start__c: '',
            Error_Code__c: '',
            Description__c: '',
            Sample_Size__c: '',
            impactedParts: [{
                Part_Name__c: '',
                Product__c: '',
                Consequence__c: '',
                Root_Cause__c: '',
                Comments__c: ''
            }]
        });
        this.tfrList = [...this.tfrList];
    }

    removeTFR(event) {
        const index = event.target.dataset.index;
        this.tfrList.splice(index, 1);
        this.tfrList = [...this.tfrList];
    }

    handleTFRChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.dataset.field;
        this.tfrList[index][field] = event.target.value;
    }

    addPart(event) {
        const index = event.target.dataset.index;
        this.tfrList[index].impactedParts.push({
            Part_Name__c: '',
            Product__c: '',
            Consequence__c: '',
            Root_Cause__c: '',
            Comments__c: ''
        });
        this.tfrList = [...this.tfrList];
    }

    removePart(event) {
        const tfrIndex = event.target.dataset.tfrIndex;
        const partIndex = event.target.dataset.partIndex;
        this.tfrList[tfrIndex].impactedParts.splice(partIndex, 1);
        this.tfrList = [...this.tfrList];
    }

    handlePartChange(event) {
        const tfrIndex = event.target.dataset.tfrIndex;
        const partIndex = event.target.dataset.partIndex;
        const field = event.target.dataset.field;
        this.tfrList[tfrIndex].impactedParts[partIndex][field] = event.target.value;
    }

    handleProductChange(event) {
        const tfrIndex = event.target.dataset.tfrIndex;
        const partIndex = event.target.dataset.partIndex;
        const productId = event.detail.recordId;
        this.tfrList[tfrIndex].impactedParts[partIndex].Product__c = productId;
    }

    async handleSubmit() {
        debugger;
        this.isLoading = true;
        let isValid = true;

        for (let tfr of this.tfrList) {
            if (!tfr.VIN_Start__c || !tfr.Error_Code__c || !tfr.Sample_Size__c) {
                isValid = false;
                break;
            }

            for (let part of tfr.impactedParts) {
                const missing = !part.Part_Name__c || !part.Product__c || !part.Consequence__c || !part.Root_Cause__c;
                part.hasError = missing;
                part.rowClass = missing ? 'slds-box slds-theme_default slds-m-vertical_small error-row' : 'slds-box';
                if (missing) isValid = false;
            }
        }

        this.tfrList = [...this.tfrList];

        if (!isValid) {
            this.showToast('Validation Error', 'Please complete all required fields.', 'error');
            this.isLoading = false;
            return;
        }

        try {
            console.log(JSON.stringify(this.tfrList))
            await createMultipleTFRs({ tfrs: this.tfrList });
            this.showToast('Success', 'All TFRs created successfully', 'success');
            this.tfrList = [];
            this.addTFR();
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to create TFRs', 'error');
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}