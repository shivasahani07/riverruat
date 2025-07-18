import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import convertLeadUponStageChange from '@salesforce/apex/LeadTriggerHandler.convertLeadUponStageChange';
import Lead_OBJECT from '@salesforce/schema/Lead';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import LOST_REASON_FIELD from '@salesforce/schema/Lead.Lost_Reason__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class FollowUpDetails extends LightningElement {
    @api recordId;
    showSpinner = false;
    closedLost = false;
    formData = {};

    @track optionsStatus = [];
    @track optionsLostReason = [];

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    wiredStatus({ error, data }) {
        if (data) {
            this.optionsStatus = data.values;
        } else if (error) {
            console.error('Error in Status picklist field', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: LOST_REASON_FIELD })
    wiredLostReason({ error, data }) {
        if (data) {
            this.optionsLostReason = data.values;
        } else if (error) {
            console.error('Error in Lost Reason picklist field', JSON.stringify(error));
        }
    }

    handleChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.formData = { ...this.formData, [field]: value };
        }

        if (field === 'Status') {
            this.handleStatusChange(value);
        }
    }

    handleStatusChange(statusValue) {
        this.closedLost = (statusValue === 'Not Interested');
    }

    handleValidation() {
        debugger;
        let isValid = true;
    
        let emailCmp = this.template.querySelector(`[data-id="Email"]`);
        let phoneCmp = this.template.querySelector(`[data-id="Phone"]`);
        let dealerCodeCmp = this.template.querySelector(`[data-id="Dealer_Code__c"]`);
        let StatusCmp = this.template.querySelector(`[data-id="Status"]`);
        let lostFeedbackCmp = this.template.querySelector(`[data-id="Lost_Feedback__c"]`);
        let lostReasonCmp = this.template.querySelector(`[data-id="Lost_Reason__c"]`);
    
        // if (!this.formData.Email) {
        //     emailCmp.setCustomValidity('Please provide a valid email address.');
        //     emailCmp.reportValidity();
        //     this.showSpinner = false;
        //     throw new Error('Validation Error: Email is required.');
        // } else if (!this.formData.Email.match('.+@.+\..+')) {
        //     emailCmp.setCustomValidity('Invalid email format.');
        //     emailCmp.reportValidity();
        //     this.showSpinner = false;
        //     throw new Error('Validation Error: Invalid email format.');
        // } else {
        //     emailCmp.setCustomValidity('');
        //     emailCmp.reportValidity();
        // }
    
        // if (!this.formData.Phone) {
        //     phoneCmp.setCustomValidity('Please provide the phone number.');
        //     phoneCmp.reportValidity();
        //     this.showSpinner = false;
        //     throw new Error('Validation Error: Phone number is required.');
        // } else {
        //     phoneCmp.setCustomValidity('');
        //     phoneCmp.reportValidity();
        // }
    
        // if (!this.formData.DealerCode) {
        //     dealerCodeCmp.setCustomValidity('Please provide the dealer code.');
        //     dealerCodeCmp.reportValidity();
        //     this.showSpinner = false;
        //     throw new Error('Validation Error: Dealer code is required.');
        // } else {
        //     dealerCodeCmp.setCustomValidity('');
        //     dealerCodeCmp.reportValidity();
        // }

        if (!this.formData.Status) {
            StatusCmp.setCustomValidity('Please provide the Status.');
            StatusCmp.reportValidity();
            this.showSpinner = false;
            throw new Error('Validation Error: Status is required.');
        } else {
            StatusCmp.setCustomValidity('');
            StatusCmp.reportValidity();
        }
    
        if (this.formData.Status === 'Not Interested') {
            if (!this.formData.LostFeedback) {
                lostFeedbackCmp.setCustomValidity('Please provide Lost Feedback.');
                lostFeedbackCmp.reportValidity();
                this.showSpinner = false;
                throw new Error('Validation Error: Lost Feedback is required.');
            } else {
                lostFeedbackCmp.setCustomValidity('');
                lostFeedbackCmp.reportValidity();
            }
    
            if (!this.formData.LostReason) {
                lostReasonCmp.setCustomValidity('Please provide Lost Reason.');
                lostReasonCmp.reportValidity();
                this.showSpinner = false;
                throw new Error('Validation Error: Lost Reason is required.');
            } else {
                lostReasonCmp.setCustomValidity('');
                lostReasonCmp.reportValidity();
            }
        }
    
        return isValid;
    }
    
    
    
    handleSave() {
        debugger;
        this.showSpinner = true;
    
        if (!this.handleValidation()) {
            this.showSpinner = false;
            return;
        }
    
        convertLeadUponStageChange({ recordId: this.recordId, formData: this.formData })
            .then(result => {
                this.showSpinner = false;
                if (result === 'SUCCESS') {
                    this.showToast('success', 'Lead updated successfully!', 'success');
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else if(result === `Create a Test Drive before converting the lead`){
                    this.showToast('error', result, 'error');
                }else if(result === `Test Drive should be scheduled before converting the lead`){
                    this.showToast('error', result, 'error');
                }else if(result === `No pincodes associated with this postal code, so we cannot convert this lead`){
                    this.showToast('error', result, 'error');
                }else {
                    this.showToast('error', result, 'error');
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.error("Error: " + error);
                this.showToast('Error', 'An error occurred while processing the lead.', 'error');
            });
    }
    


    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }
}