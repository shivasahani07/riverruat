import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CUSTOMER_CONCERN_OBJECT from '@salesforce/schema/Customer_Concern__c';

import getConcernsByCaseId from '@salesforce/apex/CaseCustomerConcernController.getConcernsByCaseId';
import updateConcerns from '@salesforce/apex/CaseCustomerConcernController.updateConcerns';

export default class CustomerConcernManager extends LightningElement {
    @api recordId;

    @track concerns = [];
    @track error;

    categoryOptions = [];
    concernOptionsMap = {}; // Case_Category__c → [Concerns__c]
    subConcernOptionsMap = {}; // Concerns__c → [Subconcerns__c]

    @wire(getObjectInfo, { objectApiName: CUSTOMER_CONCERN_OBJECT })
    objectInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: CUSTOMER_CONCERN_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    wiredPicklists({ error, data }) {
        if (data) {
            this.categoryOptions = data.picklistFieldValues.Case_Category__c.values;

            const concernField = data.picklistFieldValues.Concerns__c;
            const subConcernField = data.picklistFieldValues.Subconcerns__c;

            concernField.controllerValues &&
                concernField.values.forEach(option => {
                    option.validFor.forEach(validKey => {
                        const controllerKey = Object.entries(concernField.controllerValues)
                            .find(([, v]) => v === validKey)?.[0];
                        if (!this.concernOptionsMap[controllerKey]) {
                            this.concernOptionsMap[controllerKey] = [];
                        }
                        this.concernOptionsMap[controllerKey].push({ label: option.label, value: option.value });
                    });
                });

            subConcernField.controllerValues &&
                subConcernField.values.forEach(option => {
                    option.validFor.forEach(validKey => {
                        const controllerKey = Object.entries(subConcernField.controllerValues)
                            .find(([, v]) => v === validKey)?.[0];
                        if (!this.subConcernOptionsMap[controllerKey]) {
                            this.subConcernOptionsMap[controllerKey] = [];
                        }
                        this.subConcernOptionsMap[controllerKey].push({ label: option.label, value: option.value });
                    });
                });
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        getConcernsByCaseId({ caseId: this.recordId }).then(data => {
            const cloned = JSON.parse(JSON.stringify(data));
            this.concerns = cloned.map(rec => ({
                ...rec,
                concernOptions: this.getConcernOptions(rec.Case_Category__c),
                subConcernOptions: this.getSubConcernOptions(rec.Concerns__c)
            }));
        }).catch(err => {
            this.error = err;
        });
    }

    getConcernOptions(category) {
        return this.concernOptionsMap[category] || [];
    }

    getSubConcernOptions(concern) {
        return this.subConcernOptionsMap[concern] || [];
    }

    handleCategoryChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        record.Case_Category__c = value;
        record.Concerns__c = null;
        record.Subconcerns__c = null;
        record.concernOptions = this.getConcernOptions(value);
        record.subConcernOptions = [];
    }

    handleConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        record.Concerns__c = value;
        record.Subconcerns__c = null;
        record.subConcernOptions = this.getSubConcernOptions(value);
    }

    handleSubConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        record.Subconcerns__c = value;
    }

    handleSave() {
        updateConcerns({ concerns: this.concerns })
            .then(() => {
                // Optionally refresh or show toast
            })
            .catch(error => {
                this.error = error.body.message;
            });
    }
}