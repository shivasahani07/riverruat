import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import convertLeadUponStageChange from '@salesforce/apex/LeadTriggerHandler.convertLeadUponStageChange';
import getOpportunityId from '@salesforce/apex/LeadTriggerHandler.getOpportunityId';
import Lead_OBJECT from '@salesforce/schema/Lead';
import STATUS_FIELD from '@salesforce/schema/Lead.Status';
import LOST_REASON_FIELD from '@salesforce/schema/Lead.Lost_Reason__c';
import Lead_Secondary_DropOut_Reasons_FIELD from '@salesforce/schema/Lead.Lead_Secondary_DropOut_Reasons__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class FollowUpDetails extends LightningElement {
    @api recordId;
    showSpinner = false;
    closedLost = false;
    reason = false; // ✅ Added tracking for feedback textarea toggle
    formData = {};

    @track optionsStatus = [];
    @track optionsLostReason = [];
    @track filteredSubReasons = [];
    fullSubReasonMap = {};
    allSubReasonOptions = [];

    @wire(getObjectInfo, { objectApiName: Lead_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredStatus({ error, data }) {
        if (data) {
            this.optionsStatus = data.values;
        } else {
            console.error('Error in Status picklist field', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: LOST_REASON_FIELD
    })
    wiredReason({ data, error }) {
        if (data) {
            this.optionsLostReason = data.values;
        } else {
            console.error('Error loading Lost Reason:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: Lead_Secondary_DropOut_Reasons_FIELD
    })
    wiredSubReason({ data, error }) {
        if (data) {
            this.fullSubReasonMap = data.controllerValues;
            this.allSubReasonOptions = data.values;
        } else {
            console.error('Error loading Sub Reason:', error);
        }
    }

    handleChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.formData = { ...this.formData, [field]: value };
        }

        if (field === 'Status') {
            this.closedLost = (value === 'Drop Out');
        }

        if (field === 'LostReason') {
            const controllerValue = this.fullSubReasonMap[value];
            if (controllerValue !== undefined) {
                this.filteredSubReasons = this.allSubReasonOptions.filter(opt => opt.validFor.includes(controllerValue));
            } else {
                this.filteredSubReasons = [];
            }
        }
        if (field === 'LostSubReason' && value === 'Others') {
            this.reason = true;
        }
    }

    // handleValidation() {
    //     let StatusCmp = this.template.querySelector(`[data-id="Status"]`);
    //     let lostFeedbackCmp = this.template.querySelector(`[data-id="Lost_Feedback__c"]`);
    //     let lostReasonCmp = this.template.querySelector(`[data-id="Lost_Reason__c"]`);
    //     let lostSubReasonCmp = this.template.querySelector(`[data-id="Lead_Secondary_DropOut_Reasons__c"]`);

    //     if (!this.formData.Status) {
    //         StatusCmp.setCustomValidity('Please provide the Status.');
    //         StatusCmp.reportValidity();
    //         this.showSpinner = false;
    //         throw new Error('Validation Error: Status is required.');
    //     } else {
    //         StatusCmp.setCustomValidity('');
    //         StatusCmp.reportValidity();
    //     }

    //     if (this.formData.Status === 'Drop Out') {
    //         if (!this.formData.LostFeedback) {
    //             lostFeedbackCmp.setCustomValidity('Please provide Lost Feedback.');
    //             lostFeedbackCmp.reportValidity();
    //             this.showSpinner = false;
    //             throw new Error('Validation Error: Lost Feedback is required.');
    //         } else {
    //             lostFeedbackCmp.setCustomValidity('');
    //             lostFeedbackCmp.reportValidity();
    //         }

    //         if (!this.formData.LostReason) {
    //             lostReasonCmp.setCustomValidity('Please provide Lost Reason.');
    //             lostReasonCmp.reportValidity();
    //             this.showSpinner = false;
    //             throw new Error('Validation Error: Lost Reason is required.');
    //         } else {
    //             lostReasonCmp.setCustomValidity('');
    //             lostReasonCmp.reportValidity();
    //         }
    //         if (!this.formData.LostSubReason) {
    //             lostSubReasonCmp.setCustomValidity('Please provide Lost Reason.');
    //             lostSubReasonCmp.reportValidity();
    //             this.showSpinner = false;
    //             throw new Error('Validation Error: Lost Reason is required.');
    //         } else {
    //             lostSubReasonCmp.setCustomValidity('');
    //             lostSubReasonCmp.reportValidity();
    //         }
    //     }

    //     return true;
    // }

    handleSave() {
        debugger;
        this.showSpinner = true;

        // if (!this.handleValidation()) {
        //     this.showSpinner = false;
        //     return;
        // }

        if (this.formData == null) {
            this.showToast('Warning', 'Please Fill Mandatory Fields', 'error');
            this.showSpinner = false;
            return;
        }
        if (this.formData.Status == null) {
            this.showToast('Warning', 'Please Fill Status Fields', 'error');
            this.showSpinner = false;
            return;
        }
        if (this.formData.Status == 'Drop Out' && (this.formData.LostReason == null || this.formData.LostSubReason == null)) {
            this.showToast('Warning', 'Please Fill Mandatory Fields', 'error');
            this.showSpinner = false;
            return;
        }
        if (this.formData.LostSubReason == 'Others' && (this.formData.LostFeedback == '' || this.formData.LostFeedback == undefined || this.formData.LostFeedback == null)) {
            this.showToast('Warning', 'Please Fill LostFeedback', 'error');
            this.showSpinner = false;
            return;
        }

        convertLeadUponStageChange({ recordId: this.recordId, formData: this.formData })
            .then(result => {
                if (result === 'SUCCESS') {
                    this.dispatchEvent(new CloseActionScreenEvent());
                    setTimeout(() => {
                        this.showToast('Success', 'Lead updated successfully!', 'success');
                        this.doSearch();
                    }, 4000);
                } else {
                    this.showToast('Error', result, 'error');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error("Error: " + error);
                this.showToast('Error', 'An error occurred while processing the lead.', 'error');
            });
    }

    doSearch() {
        getOpportunityId({ recordId: this.recordId })
            .then(result => {
                if (result !== null) {
                    window.location.href = '/' + result;
                }
            })
            .catch(error => {
                console.error('Navigation error: ', error);
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }
}