import { LightningElement, api, track } from 'lwc';
import getRecordDeatil from '@salesforce/apex/insuranceDetailsUpdation.getRecordDeatil';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class UpdateAllOrderDetails extends LightningElement {

    @api recordId;
    @track inhouse = false;
    @track outhouse = false;
    @track showEditFrom = false;
    showSpinner = false;
    activeSections = ['Section1', 'Section2', 'Section3', 'Section4', 'Section5'];

    connectedCallback() {
        debugger;
        if (this.recordId == null) {
            const url = window.location.href.toString();
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));
            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    const recordId = recordIdKeyValue[1];
                    this.recordId = recordId;
                } else {
                    console.error("Invalid recordId parameter format");
                }
            } else if (recordIdParam == undefined) {
                const url = window.location.href;
                const match = url.match(/\/order\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                    console.log('Record Id:', this.recordId);
                }
            }

            else {
                console.error("recordId parameter not found in the URL");
            }
        }
        this.callApexMethod();
    }

    callApexMethod() {
        debugger;
        getRecordDeatil({ recordId: this.recordId })
            .then(result => {
                if (result != null) {
                    if (result.Insurance_Type__c != null) {
                        if (result.Insurance_Type__c == 'In House') {
                            this.inhouse = true;
                        }

                        if (result.Insurance_Type__c == 'Out House') {
                            this.outhouse = true;
                        }
                    }
                    if(result.Status == 'Payment and Allocation'){
                        this.showEditFrom = true;
                    }
                }

                console.log('Apex result:', result);
            })
            .catch(error => {
                console.error('Apex error:', error);
            });

    }

    handleChange(event){
        debugger;
        const evt = event.detail.value;
        if(evt == 'Out House'){
            this.outhouse = true;
            this.inhouse = false;
        }
        if(evt == 'In House'){
            this.inhouse = true;
            this.outhouse = false;
        }
    }

    handleSubmit(event) {
        debugger;
            this.showSpinner = true;
            event.preventDefault(); 
            const fields = event.detail.fields;
            if(this.inhouse == true){
                fields.Other_Insurance_Provider_Name__c = ''; 
            }
            if(this.outhouse == true){
                fields.Insurance__c = ''; 
            }
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }

    handleSuccess() {
        debugger;
        const successToast = new ShowToastEvent({
            title: 'Record Saved Successfully',
            message: 'Your changes have been updated.',
            variant: 'success'
        });
        this.dispatchEvent(successToast);
        this.showSpinner = false;
        this.closeQuickAction();
    }

    handleCancel(){
        debugger;
        this.closeQuickAction();
    }

    handleError(event) {
        debugger;
        this.showSpinner = false;
        const errorToast = new ShowToastEvent({
            title: 'Error Saving Record',
            message: event.detail?.message || event.detail?.output?.errors?.[0]?.message,
            variant: 'error'
        });
        this.dispatchEvent(errorToast);
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}