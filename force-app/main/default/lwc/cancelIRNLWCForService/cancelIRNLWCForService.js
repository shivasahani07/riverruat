import { LightningElement, track, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';
import cancelIRN_EInvoice from '@salesforce/apex/ClearTaxAPiHelperForService.cancelIRN_EInvoice';
import { updateRecord } from 'lightning/uiRecordApi';
const FIELDS = ['WorkOrder.IRN_No__c'];


export default class CancelIRNLWCForService extends LightningElement {
     @track selectedReason = '';
        @track irnValue = '';
        @track irnRemarksValue = ''; 
        @track showSpinner = false;
       
    
    
        @track showToast = false;
        @track toastMessage = '';
        @track toastVariant = 'success';
        @track toastClass = 'toast'; 
        @track IsshowCancelBtn = true;
        @api recordId;
        @track closeScreen;
    
        connectedCallback() {
            
                this.recordId = this.recordId;
                if(this.recordId == undefined || this.recordId == null){
                    if (this.recordId == undefined) {
                        const url = window.location.href;
                        const match = url.match(/\/WorkOrder\/([^/]+)/);
                        if (match) {
                            this.recordId = match[1];
                            console.log('Record Id:', this.recordId);
                        }
                    }
                    this.recordId = this.recordId;
                }
        }
        
    
        @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
        wiredOrderdata({ error, data }) {
            if (data) {
                this.irnValue = data.fields.IRN_No__c.value;
                console.log('Order Data:', data.fields);
            } else if (error) {
                console.error('Error retrieving order data:', error);
            }
        }
    
        reasonOptions = [
            { label: 'Duplicate', value: '1' },
            { label: 'Wrong Data Entry', value: '2' },
            { label: 'Order Cancelled', value: '3' },
            { label: 'Others', value: '4' }
        ];
    
        handleReasonChange(event) {
            this.selectedReason = event.target.value;
        }
    
        handleIRNRemarksChange(event) {
            this.irnRemarksValue = event.target.value;
        }
    
        handleCancelIRN() {
            debugger;
            if (!this.selectedReason) {
                this.closeScreen = 'No';
                this.showToastMessage(' Please select a reason!', 'error');
                return;
            }
            if (!this.irnRemarksValue) {
                this.closeScreen = 'No';
                this.showToastMessage(' Please Enter Remarks!', 'error');
                return;
            }
    
            this.showSpinner = true;
            this.IsshowCancelBtn = false;
            cancelIRN_EInvoice({
                cancellationReason: this.selectedReason,
                cancellationRemark: this.irnRemarksValue,
                WorkOrderId: this.recordId
            })
            .then(result => {
                this.showSpinner = false;
                if (result === 'success') {
                    updateRecord({ fields: { Id: this.recordId }})
                    this.closeScreen = 'Yes';
                    this.showToastMessage('IRN Canceled Successfully!', 'success');
                } else {
                    this.showToastMessage('Error while cancelling IRN', 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.showSpinner = false;
                this.showToastMessage('Error while cancelling IRN', 'error');
            });
        }
    
        showToastMessage(message, variant) {
            debugger;
            this.toastMessage = message;
            this.toastVariant = variant;
            this.showToast = true;
            this.toastClass = `toast ${variant === 'success' ? 'success-toast' : 'error-toast'}`;
    
            setTimeout(() => {
                this.toastClass += ' toast-hide'; 
                setTimeout(() => {
                    this.showToast = false;
                    if (this.closeScreen === 'No') {
                        return;
                    }else{
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }
                }, 500); 
            }, 2000); 
        }
}