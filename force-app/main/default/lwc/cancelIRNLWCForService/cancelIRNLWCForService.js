import { LightningElement, track, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import cancelIRN_EInvoice from '@salesforce/apex/ClearTaxAPiHelperForService.cancelIRN_EInvoice';
import cancelIRN_InsurenceEInvoice from '@salesforce/apex/CleartaxAPIHelperForServiceInsurance.cancelIRN_EInvoice';

const FIELDS = [
    'WorkOrder.IRN_No__c', 
    'WorkOrder.IRN_No_Insurance__c',
    'WorkOrder.IRN_Generated_DateTime__c',
    'WorkOrder.IRN_Generated_DateTime_Insurance__c'
];

export default class CancelIRNLWCForService extends LightningElement {
    @api recordId;

    @track selectedIRNType = '';
    @track irnValue = '';
    @track irnInsuranceValue = '';
    @track serviceIRNDate;
    @track insuranceIRNDate;

    @track selectedReason = '';
    @track irnRemarksValue = '';
    @track showSpinner = false;
    @track showToast = false;
    @track IsshowCancelBtn = true;
    @track toastMessage = '';
    @track toastClass = 'toast';

    irnTypeOptions = [
        { label: 'Service IRN', value: 'Service' },
        { label: 'Insurance IRN', value: 'Insurance' }
    ];

    reasonOptions = [
        { label: 'Duplicate', value: '1' },
        { label: 'Wrong Data Entry', value: '2' },
        { label: 'Order Cancelled', value: '3' },
        { label: 'Others', value: '4' }
    ];

    get isServiceSelected() {
        return this.selectedIRNType === 'Service';
    }

    get isInsuranceSelected() {
        return this.selectedIRNType === 'Insurance';
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOrderdata({ data }) {
        if (data) {
            this.irnValue = data.fields.IRN_No__c.value;
            this.irnInsuranceValue = data.fields.IRN_No_Insurance__c.value;
            this.serviceIRNDate = data.fields.IRN_Generated_DateTime__c.value;
            this.insuranceIRNDate = data.fields.IRN_Generated_DateTime_Insurance__c.value;
        }
    }

    

    handleIRNTypeChange(event) {
        this.selectedIRNType = event.target.value;
    }

    handleBack() {
        this.selectedIRNType = '';
        this.selectedReason = '';
        this.irnRemarksValue = '';
    }

    handleReasonChange(e) { this.selectedReason = e.target.value; }
    handleIRNRemarksChange(e) { this.irnRemarksValue = e.target.value; }

    handleSubmit() {

        if (this.isServiceSelected && (!this.irnValue || this.irnValue.trim() === '')) {
        this.showToastMsg('Service IRN cannot be blank!', 'error');
        return;
    }

    if (this.isInsuranceSelected && (!this.irnInsuranceValue || this.irnInsuranceValue.trim() === '')) {
        this.showToastMsg('Insurance IRN cannot be blank!', 'error');
        return;
    }

        if (!this.selectedReason || !this.irnRemarksValue) {
            this.showToastMsg('Please fill all fields', 'error');
            return;
        }

        const irnTime = this.isServiceSelected ? this.serviceIRNDate : this.insuranceIRNDate;
        const now = new Date();
        const diffHrs = (now - new Date(irnTime)) / (1000 * 60 * 60);

        if (diffHrs > 24) {
            this.showToastMsg('IRN can only be cancelled within 24 hours!', 'error');
            return;
        }

        this.showSpinner = true;
        this.IsshowCancelBtn = false;

        const params = {
            cancellationReason: this.selectedReason,
            cancellationRemark: this.irnRemarksValue,
            WorkOrderId: this.recordId
        };

        const apexCall = this.isServiceSelected ? cancelIRN_EInvoice : cancelIRN_InsurenceEInvoice;

        apexCall(params)
            .then(res => {
                this.showSpinner = false;
                if (res === 'success') {
                    updateRecord({ fields: { Id: this.recordId }});
                    this.showToastMsg('IRN canceled successfully', 'success', true);
                } else {
                    this.showToastMsg('Cancellation failed', 'error');
                }
            })
            .catch(() => {
                this.showSpinner = false;
                this.showToastMsg('Error cancelling IRN', 'error');
            });
    }

    showToastMsg(msg, variant, close = false) {
        this.toastMessage = msg;
        this.toastClass = `toast ${variant}-toast`;
        this.showToast = true;

        setTimeout(() => {
            this.showToast = false;
            if (close) this.dispatchEvent(new CloseActionScreenEvent());
        }, 2500);
    }
}