import { LightningElement, track } from 'lwc';
import createMultipleTFRs from '@salesforce/apex/TFRController.createMultipleTFRs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TfrCreator extends LightningElement {
    @track tfrList = [];
    @track isLoading = false;

    connectedCallback() {
        this.addTFR(); // Initialize with 1 TFR
    }

    addTFR() {
        this.tfrList.push({
            vin: '',
            errorCode: '',
            description: '',
            Required_Sampe_No:'',
            impactedParts: [{
                partName: '',
                partCode: '',
                consequence: '',
                rootCause: '',
                comments: ''
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
            partName: '',
            partCode: '',
            consequence: '',
            rootCause: '',
            comments: ''
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
        this.tfrList[tfrIndex].impactedParts[partIndex].partCode = productId;
    }

    async handleSubmit() {
        // Validate all TFRs and 
        debugger;
        this.isLoading=true
        let isValid = true;

        for (let tfr of this.tfrList) {
            if (!tfr.vin || !tfr.errorCode) {
                isValid = false;
                break;
            }

            for (let part of tfr.impactedParts) {
                const missing = !part.partName || !part.partCode || !part.consequence || !part.rootCause;
                part.hasError = missing;
                part.rowClass = missing ? 'slds-box slds-theme_default slds-m-vertical_small error-row' : 'slds-box';
                if (missing) isValid = false;
            }
        }

        this.tfrList = [...this.tfrList]; // re-render

        if (!isValid) {
            this.showToast('Validation Error', 'Please complete all required fields.', 'error');
            this.isLoading=false;
            return;
        }

        try {
            console.log(JSON.stringify(this.tfrList))
            await createMultipleTFRs({ tfrs: this.tfrList });
            this.showToast('Success', 'All TFRs created successfully', 'success');
            this.tfrList = [];
            this.addTFR(); // Start fresh
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to create TFRs', 'error');
            this.isLoading=false;
            console.error(error);
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);;
    }
}