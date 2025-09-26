import { LightningElement, api, wire, track } from 'lwc';
import getTFRLabourEffects from '@salesforce/apex/AddFailureCodeControllerNew.getTFRLabourEffects';
import saveLabourEffects from '@salesforce/apex/AddFailureCodeControllerNew.CreateLabourCodeForFalireCodes';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import { refreshApex } from '@salesforce/apex';


export default class TfrLabourEffectManager extends NavigationMixin(LightningElement) {


    @api recordId; // Failure_Code__c Id
    @track existingEffects = [];
    @track selectedLabourCodes = [];
    @track disableHandleSave = false;
    @track refreshResultData;
    @track selectedLabourCode = null; // bind to record-id


    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Labour Code', fieldName: 'Labour_Code__c' },
        { label: 'Labour Name', fieldName: 'Labour_Code__r.Name' }
    ];


    // Fetch existing Labour Effects
    @wire(getTFRLabourEffects, { failureCodeId: '$recordId' })
    wiredEffects(result) {
        debugger;

        this.refreshResultData = result;

        if (result.data) {
            this.existingEffects = result.data;
        } else if (result.error) {
            console.error('Error fetching effects', result.error);
        }
    }

    // Capture selected Labour Codes from record pickers
    codesetids = [];

    /*
    handleLabourSelect(event) {
        debugger;
        const index = event.target.dataset.id;
        const labourId = event.detail.recordId;
        if (labourId && !this.selectedLabourCodes.includes(labourId)) {
            this.selectedLabourCodes = [...this.selectedLabourCodes, labourId];
        }

        this.codesetids.push(labourId);
        console.log('this.selectedLabourCodes : ' + this.selectedLabourCodes);
    }
    */

    handleLabourSelect(event) {
        const labourId = event.detail.recordId;

        if (!labourId) {
            this.disableHandleSave = false; // re-enable Save button
            return;
        }

        // Check if already exists in existingEffects
        const alreadyExists = this.existingEffects.some(effect => effect.Code_Set__c === labourId);

        if (alreadyExists) {
            this.showToastMessage('Duplicate Selection', 'This Labour Code is already linked to the Failure Code.', 'warning');
            this.disableHandleSave = true;
            return;
        }

        // Check if user already picked it in this session
        if (labourId && !this.selectedLabourCodes.includes(labourId)) {
            this.selectedLabourCodes = [...this.selectedLabourCodes, labourId];
            this.codesetids.push(labourId);
        }
    }

    clearSelection() {
        this.selectedLabourCode = null;
    }


    // Save new records
    handleSave() {
        debugger;
        if (this.selectedLabourCodes.length === 0) {
            alert('Please select at least one Labour Code.');
            return;
        }
        this.disableHandleSave = true;
        

        saveLabourEffects({ failureCodeId: this.recordId, CodesetsIds: this.codesetids })

            .then(() => {
                this.selectedLabourCodes = [];
                this.showToastMessage('Success !!', 'Labour Effects Record Created Successfully !!', 'success');
                this.codesetids = [];
                this.clearSelection();
                this.handleClearSelection();
                return refreshApex(this.refreshResultData);

            })
            .catch(error => {
                console.error('Error saving effects', error);
                this.showToastMessage('Error !!', 'Error Creating Labour Effects Record !!', 'error');
                this.disableHandleSave = false;
            });
    }

    handleClearSelection() {
        const myPicker = this.refs.myPicker;
        if (myPicker) {
            myPicker.clearSelection(); // Clear the visual selection
            this.selectedLabourCode = null;
        }
    }
    
    showToastMessage(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    navigateToContactRelatedList() {
        this[NavigationMixin.Navigate]({
            type: '',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                relationshipApiName: 'Contacts',
                actionName: 'view'
            },
        });
    }
}