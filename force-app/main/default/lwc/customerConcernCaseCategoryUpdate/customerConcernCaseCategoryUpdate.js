import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CUSTOMER_CONCERN_OBJECT from '@salesforce/schema/Customer_Concern__c';

import getConcernsByCaseId from '@salesforce/apex/CaseCustomerConcernController.getConcernsByCaseId';
import updateConcerns from '@salesforce/apex/CaseCustomerConcernController.updateConcerns';
import getUserProfileName from '@salesforce/apex/CaseCustomerConcernController.getUserProfileName';

export default class CustomerConcernManager extends LightningElement {
    @api recordId;
    @track concerns = [];
    @track error;
    @track isSystemAdmin = false;

    updateCategoryOptions = [];
    allConcernOptions = [];
    concernControllerMap = {};
    allSubConcernOptions = [];
    subConcernMap = {};
    subConcernControllerMap = {};

    @wire(getObjectInfo, { objectApiName: CUSTOMER_CONCERN_OBJECT })
    objectInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: CUSTOMER_CONCERN_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    wiredPicklists({ error, data }) {
        if (data) {
            this.updateCategoryOptions = data.picklistFieldValues.Case_Category_Update__c?.values || [];
            this.allConcernOptions = data.picklistFieldValues.Concerns__c?.values || [];
            this.concernControllerMap = data.picklistFieldValues.Concerns__c.controllerValues;

            this.allSubConcernOptions = data.picklistFieldValues.Subconcerns__c?.values || [];
            this.subConcernControllerMap = data.picklistFieldValues.Subconcerns__c.controllerValues;

            this.allSubConcernOptions.forEach(item => {
                item.validFor.forEach(index => {
                    if (!this.subConcernMap[index]) {
                        this.subConcernMap[index] = [];
                    }
                    this.subConcernMap[index].push({ label: item.label, value: item.value });
                });
            });

            this.loadConcerns();
        } else if (error) {
            this.error = error.body?.message || JSON.stringify(error);
        }
    }

    connectedCallback() {
        getUserProfileName()
            .then(profile => {
                this.isSystemAdmin = profile === 'System Administrator';
            })
            .catch(error => {
                this.error = 'Error fetching user profile: ' + (error.body?.message || JSON.stringify(error));
            });
            if (!this.recordId) {
            const url = window.location.href;
            const match = url.match(/\/case\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }
    }

    loadConcerns() {
        getConcernsByCaseId({ caseId: this.recordId })
            .then(data => {
                this.concerns = (data || []).map(c => {
                    const concernOptions = this.getConcernOptions(c.Case_Category__c);
                    const subConcernOptions = this.getSubConcernOptions(c.Concerns__c);
                    return {
                        ...c,
                        concernOptions,
                        subConcernOptions
                    };
                });
            })
            .catch(err => {
                this.error = err.body?.message || JSON.stringify(err);
            });
    }

    getConcernOptions(categoryValue) {
        const controllerIndex = this.concernControllerMap[categoryValue];
        return this.allConcernOptions.filter(opt => opt.validFor.includes(controllerIndex));
    }

    getSubConcernOptions(concernValue) {
        const controllerIndex = this.subConcernControllerMap[concernValue];
        return this.subConcernMap[controllerIndex] || [];
    }

    handleConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        if (record) {
            record.Concerns__c = value;
            record.Subconcerns__c = '';
            record.subConcernOptions = this.getSubConcernOptions(value);
        }
    }

    handleSubConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        if (record) {
            record.Subconcerns__c = value;
        }
    }

    handleUpdateCategoryChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        if (record) {
            record.Case_Category_Update__c = value;
        }
    }

    handleClosedResolutionChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        if (record) {
            record.Closed_Resolution__c = value;
        }
    }

    handleSave() {
        updateConcerns({ concerns: this.concerns })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Customer Concerns have been updated',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.error = error.body?.message || JSON.stringify(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating Customer Concerns',
                        message: this.error,
                        variant: 'error'
                    })
                );
            });
    }
}