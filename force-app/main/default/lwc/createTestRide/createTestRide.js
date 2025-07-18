import { LightningElement, track, api,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createEvent from '@salesforce/apex/OpportunityTriggerHandler.createEvent';
import Account from '@salesforce/schema/Test_Drive__c';
import RATING_FIELD from '@salesforce/schema/Test_Drive__c.Test_Drive_Status__c';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';


export default class CreateTestRide extends LightningElement {

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
        let startDate = this.template.querySelector('.startDate');
        let endDate = this.template.querySelector('.endDate');
        let Status = this.template.querySelector('.Status');

        // if (startDate && !startDate.value) {
        //     startDate.setCustomValidity('Please provide the name value');
        //     isValid = false;
        //     this.showSpinner = false;
        // } else {
        //     startDate.setCustomValidity('');
        // }
        // startDate.reportValidity();

        // if (endDate && !endDate.value) {
        //     endDate.setCustomValidity('Please provide the date value.');
        //     isValid = false;
        //     this.showSpinner = false;
        // } else {
        //     endDate.setCustomValidity('');
        // }
        // endDate.reportValidity();

        if (Status && !Status.value) {
            Status.setCustomValidity('Please provide the Status value.');
            isValid = false;
            this.showSpinner = false;
        } else {
            Status.setCustomValidity('');
        }
        Status.reportValidity();

        if (!isValid) {
            return;
        }

        if (this.dateObj) {
            createEvent({ dateObj: this.dateObj })
                .then(result => {
                    if (result === 'Event successfully created without dates: ') {
                        this.showToast('SUCCESS' ? 'Event Scheduled Successfully' : 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSpinner = false;
                        setTimeout(() => {
                            window.location.reload();
                        }, 3000);
                    }else if (result === 'Event Created Successfully') {
                        this.showToast('SUCCESS' ? 'Event Created Successfully' : 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSpinner = false;
                    }  else {
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