import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import TestDrive_OBJECT from '@salesforce/schema/Test_Drive__c';
import Oppo_OBJECT from '@salesforce/schema/Opportunity';
import STATUS_FIELD from '@salesforce/schema/Test_Drive__c.Test_Drive_Status__c';
import LOST_REASON_FIELD from '@salesforce/schema/Opportunity.Drop_Out_Reasons__c';
import LOST_SUB_REASON_FIELD from '@salesforce/schema/Opportunity.Drop_Out_Sub_Reasons__c';
import updateTestDriveStatus from '@salesforce/apex/TestDriveTriggerHandler.updateTestDriveStatus';

export default class UpdateTestDrive extends LightningElement {
    @api recordId;
    showFields = false;
    otherReason = false;

    @track statusOptions = [];
    @track reasonOptions = [];
    @track subReasonOptions = [];
    @track allSubReasonOptions = [];
    @track fullSubReasonMap = {};

    status;
    reason;
    subReason;
    others;

    @wire(getObjectInfo, { objectApiName: TestDrive_OBJECT })
    testDriveObjectInfo;

    @wire(getObjectInfo, { objectApiName: Oppo_OBJECT })
    oppObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$testDriveObjectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredStatus({ data, error }) {
        if (data) {
            this.statusOptions = data.values;
        } else if (error) {
            console.error('Error loading Test Drive Status:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$oppObjectInfo.data.defaultRecordTypeId',
        fieldApiName: LOST_REASON_FIELD
    })
    wiredReason({ data, error }) {
        if (data) {
            this.reasonOptions = data.values;
        } else if (error) {
            console.error('Error loading Drop Out Reasons:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$oppObjectInfo.data.defaultRecordTypeId',
        fieldApiName: LOST_SUB_REASON_FIELD
    })
    wiredSubReason({ data, error }) {
        if (data) {
            this.fullSubReasonMap = data.controllerValues;
            this.allSubReasonOptions = data.values;
        } else if (error) {
            console.error('Error loading Drop Out Sub Reasons:', error);
        }
    }

    handleChange(event) {
        const { name, value } = event.target;
        
        if (name === 'TestDriveStatus') {
            this.status = value;
            this.showFields = value === 'Canceled';
            if (value !== 'Canceled') {
                this.reason = '';
                this.subReason = '';
                this.others = '';
                this.otherReason = false;
            }
        } 
        else if (name === 'DropOutReason') {
            this.reason = value;
            if (this.fullSubReasonMap && value) {
                const controllerKey = this.fullSubReasonMap[value];
                this.subReasonOptions = this.allSubReasonOptions.filter(
                    opt => opt.validFor.includes(controllerKey)
                );
            }
            this.subReason = '';
            this.otherReason = false;
        } 
        else if (name === 'DropOutSubReason') {
            this.subReason = value;
            this.otherReason = value === 'Others – need reason';
            if (!this.otherReason) this.others = '';
        } 
        else if (name === 'Others') {
            this.others = value;
        }
    }

    handleSave() {
        debugger;
        if (!this.validateFields()) return;
        
        updateTestDriveStatus({
            recordId: this.recordId,
            status: this.status,
            reason: this.reason,
            subReason: this.subReason,
            others: this.others
        })
        .then(() => {
            this.showToast('Success', 'Test Drive updated successfully', 'success');
            this.closeAction();
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
            console.error('Update error:', error);
        });
    }

    validateFields() {
        if (!this.status) {
            this.showToast('Error', 'Test Drive Status is required', 'error');
            return false;
        }
        
        if (this.showFields) {
            if (!this.reason) {
                this.showToast('Error', 'Drop Out Reason is required', 'error');
                return false;
            }
            if (!this.subReason) {
                this.showToast('Error', 'Drop Out Sub Reason is required', 'error');
                return false;
            }
            if (this.otherReason && !this.others) {
                this.showToast('Error', 'Others field is required', 'error');
                return false;
            }
        }
        return true;
    }

    handleCancel() {
        this.closeAction();
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}