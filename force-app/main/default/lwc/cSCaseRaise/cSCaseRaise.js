import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import CASE_OBJECT from '@salesforce/schema/Case';
import SUBCATEGORY_FIELD from '@salesforce/schema/Case.Case_Sub_Category__c';
import COUPON_FOR from '@salesforce/schema/Case.Coupon_For__c';
import createCase from '@salesforce/apex/CSCaseRaiseController.createCases';
import getAccountName from '@salesforce/apex/CSCaseRaiseController.getAccountName';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CSCaseRaise extends LightningElement {
    @api recordId;
    accountName;
    @track subcategoryOptions = [];
    subcategory = '';
    couponValue = '';
    reason = '';
    @track couponOptions = [];
    selectedCoupon = '';
    generalQueryRecordTypeId;
    @track disableCouponFor = false;
    @track spin = false;

    connectedCallback() {
        if (!this.recordId) {
            const url = window.location.href;
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));

            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    this.recordId = recordIdKeyValue[1];
                }
            } else {
                const match = url.match(/\/Account\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                }
            }
        }

        if (this.recordId) {
            getAccountName({ accountId: this.recordId })
                .then(name => {
                    this.accountName = name;
                })
                .catch(error => {
                    console.error('Error fetching account name:', error);
                });
        } else {
            console.error('No recordId found in URL.');
        }
    }

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseMetadata({ data, error }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            for (let rtId in rtis) {
                if (rtis[rtId].name === 'General Query') {
                    this.generalQueryRecordTypeId = rtId;
                    break;
                }
            }
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$generalQueryRecordTypeId', fieldApiName: SUBCATEGORY_FIELD })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.subcategoryOptions = data.values.filter(val =>
                val.value === 'Vehicle/Accessories Purchase' || val.value === 'Website Purchase'
            );
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$generalQueryRecordTypeId', fieldApiName: COUPON_FOR })
        wiredCouponValues({ data, error }) {
            if (data) {
                this.couponOptions = data.values;
            } else if (error) {
                console.error('Error fetching coupon picklist values', error);
            }
        }

    handleCouponChange(event) {
        this.selectedCoupon = event.detail.value;
    }

    handleSubcategoryChange(event) {
            this.subcategory = event.detail.value;

            if (this.subcategory === 'Website Purchase') {
                this.selectedCoupon = 'Website';
                this.disableCouponFor = true;
            } else {
                this.selectedCoupon = '';
                this.disableCouponFor = false;
            }
    }


    handleCouponValueChange(event) {
        this.couponValue = event.detail.value;
    }

    handleReasonChange(event) {
        this.reason = event.detail.value;
    }

    handleCancel() {
     this.spin = true;
        this.subcategory = '';
        this.couponValue = '';
        this.reason = '';
         this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {

        this.spin = true; 
    if (!this.recordId) {
         this.spin = false; 
        this.showToast('Error', 'Account ID is missing.', 'error');
        return;
    }
    if (!this.selectedCoupon) {
        this.spin = false;
        this.showToast('Error', 'Please select a Coupon Type.', 'error');
        return;
    }


    if (!this.generalQueryRecordTypeId) {
         this.spin = false; 
        this.showToast('Error', 'Record Type ID is not available.', 'error');
        return;
    }

    if (!this.subcategory) {
         this.spin = false; 
        this.showToast('Error', 'Please select a Case Subcategory.', 'error');
        return;
    }

    if (!this.couponValue) {
         this.spin = false; 
        this.showToast('Error', 'Please enter a Coupon Value.', 'error');
        return;
    }
    if (this.couponValue > 20000) {
            this.spin = false;
            this.showToast('Error', 'Coupon value cannot be more than 20,000.', 'error');
            return;
        }

    if (!this.reason) {
         this.spin = false; 
        this.showToast('Error', 'Please enter a Reason for Request.', 'error');
        return;
    }

    const couponValueFloat = parseFloat(this.couponValue);
if (isNaN(couponValueFloat) || couponValueFloat <= 0) {
     this.spin = false; 
    this.showToast('Error', 'Please enter a valid coupon value.', 'error');
    return;
}
    const fields = {
        AccountId: this.recordId,
        RecordTypeId: this.generalQueryRecordTypeId,
        Case_Type__c: 'Coupon',
        Case_Sub_Category__c: this.subcategory,
        Coupon_Value__c: couponValueFloat,
        Reason_For_Request__c: this.reason,
        Coupon_Code_Approval__c : 'Pending',
        Coupon_For__c: this.selectedCoupon,
        OwnerId: USER_ID
    };

    createCase({ casesFieldsList: [fields] })
        .then(result => {
            this.showToast('Success', 'Case created successfully.', 'success');
            this.spin = false; 
            this.handleCancel();
        })
        .catch(error => {
             this.spin = false;
            this.showToast('Error', error.body.message, 'error');
        });
}


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}