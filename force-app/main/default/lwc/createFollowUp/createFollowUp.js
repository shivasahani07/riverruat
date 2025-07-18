import { LightningElement, track, api, wire } from 'lwc';
import Account from '@salesforce/schema/Follow_Up__c';
import RATING_FIELD from '@salesforce/schema/Follow_Up__c.Status__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import createFollowup from '@salesforce/apex/FollowUpTriggerController.createFollowup';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateFollowUp extends LightningElement {

    selectedValue;
    @track dateObj = {};
    @api recordId;
    showSpinner = true;
    @track optionsCategory = [];

    @wire(getObjectInfo, { objectApiName: Account })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: RATING_FIELD })
    wiredIndustryData({ error, data }) {
        debugger;
        if (data) {
            this.optionsCategory = data.values;
        } else if (error) {
            console.error('Error in Industry picklist field', JSON.stringify(error));
        }
    }

    connectedCallback() {
        debugger;
        const url = window.location.href.toString();
        const queryParams = url.split("&");

        const recordIdParam = queryParams.find(param => param.includes("recordId"));

        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");

            if (recordIdKeyValue.length === 2) {
                this.recordId = recordIdKeyValue[1];
            } else {
                console.error("Invalid recordId parameter format");
            }
        } else {
            console.error("recordId parameter not found in the URL");
        }
        this.showSpinner = false;
    }

    handleChange(event) {
        debugger;
        const { name, value } = event.target;
        this.dateObj = {
            ...this.dateObj,
            [name]: value,
            recordId: this.recordId
        };
        console.log('Updated dateObj:', JSON.stringify(this.dateObj));
    }

    handleSave() {
        let isValid = true;
        this.showSpinner = true;
        let dueDate = this.template.querySelector('.dueDate');
        let FollowUpDate = this.template.querySelector('.FollowUpDate');
        let Status = this.template.querySelector('.Status');

        if (dueDate && !dueDate.value) {
            dueDate.setCustomValidity('Please Provide the Due Date value');
            isValid = false;
            this.showSpinner = false;
        } else {
            dueDate.setCustomValidity('');
        }
        dueDate.reportValidity();

        if (Status && !Status.value) {
            Status.setCustomValidity('Please Provide the Status value');
            isValid = false;
            this.showSpinner = false;
        } else {
            Status.setCustomValidity('');
        }
        Status.reportValidity();

        if (FollowUpDate && !FollowUpDate.value) {
            FollowUpDate.setCustomValidity('Please Provide Follow-up Date value');
            isValid = false;
            this.showSpinner = false;
        } else {
            FollowUpDate.setCustomValidity('');
        }
        FollowUpDate.reportValidity();

        if (!isValid) {
            return;
        }

        if (this.dateObj) {
            createFollowup({ dateObj: this.dateObj })
                .then(result => {
                    if (result === 'Event Scheduled Successfully') {
                        this.showToast('SUCCESS' ? 'Event Scheduled Successfully' : 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSpinner = false;
                    } else if (result === `Please Complete the Recent the Follow-Up`){
                        this.showToast('Error', result, 'error');
                        this.showSpinner = false;
                    }
                    else {
                        this.showToast('Error', result, 'error');
                        this.showSpinner = false;
                    }
                })
                .catch(error => {
                    console.error("Error: " + error);
                    this.showToast('Error', 'An error occurred while converting the lead.', error);
                    this.showSpinner = false;
                });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}