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

    // Picklist values
    categoryOptions = [];
    concernOptionsMap = {}; // category → [concern]
    subConcernOptionsMap = {}; // concern → [subConcern]

    // Fetch Object Info for Record Type ID
    @wire(getObjectInfo, { objectApiName: CUSTOMER_CONCERN_OBJECT })
    objectInfo;

    // Fetch dynamic picklists
    @wire(getPicklistValuesByRecordType, {
        objectApiName: CUSTOMER_CONCERN_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    wiredPicklists({ error, data }) {
        if (data) {
            // Load controlling field values
            this.categoryOptions = data.picklistFieldValues.Case_Category__c.values;

            // Load dependent picklists
            const concernField = data.picklistFieldValues.Concerns__c;
            const subConcernField = data.picklistFieldValues.Subconcerns__c;

            concernField.controllerValues && concernField.values.forEach(option => {
                const controllerKey = Object.entries(concernField.controllerValues)
                    .find(([, v]) => v === option.validFor[0])?.[0];
                if (!this.concernOptionsMap[controllerKey]) this.concernOptionsMap[controllerKey] = [];
                this.concernOptionsMap[controllerKey].push({ label: option.label, value: option.value });
            });

            subConcernField.controllerValues && subConcernField.values.forEach(option => {
                const controllerKey = Object.entries(subConcernField.controllerValues)
                    .find(([, v]) => v === option.validFor[0])?.[0];
                if (!this.subConcernOptionsMap[controllerKey]) this.subConcernOptionsMap[controllerKey] = [];
                this.subConcernOptionsMap[controllerKey].push({ label: option.label, value: option.value });
            });
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        getConcernsByCaseId({ caseId: this.recordId }).then(data => {
            this.concerns = JSON.parse(JSON.stringify(data));
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
        record.Concern__c = null;
        record.Sub_Concern__c = null;
    }

    handleConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        record.Concern__c = value;
        record.Sub_Concern__c = null;
    }

    handleSubConcernChange(event) {
        const recId = event.target.dataset.id;
        const value = event.detail.value;
        const record = this.concerns.find(r => r.Id === recId);
        record.Sub_Concern__c = value;
    }

    handleSave() {
        updateConcerns({ concerns: this.concerns })
            .then(() => {
                // toast or refresh
            })
            .catch(error => {
                this.error = error.body.message;
            });
    }
}