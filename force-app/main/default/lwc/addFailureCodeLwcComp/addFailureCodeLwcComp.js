import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPostVINFCPCVIN from '@salesforce/apex/AddFailureCodeControllerNew.createPostVINFCPCVIN';
import validateInputs from '@salesforce/apex/AddFailureCodeControllerNew.validateInputs';
import searchFailureCodes from '@salesforce/apex/AddFailureCodeControllerNew.searchFailureCodes';

export default class AddFailureCodeLwcComp extends LightningElement {
    @track failureCode = {
        failureCode: '',
        batchSize: '',
        active: true, // Default to active
        causalProductCode: '',
        vinCutoff: '',
        isDuplicate: false,
        rowClass: ''
    };
    @track failureCodeRecordId = null
    @track DisabledhandleSave = true;
    @track messages = {};
    @track hasResults = false;
    @track isLoading = false;
    @track isShowLaborCodeComponent = false;
    @track selectedProducitId = null
    @track searchKey = '';
    @track records;
    @track selectedRecord;
    @track isDisabledFC=true;


    @track selectedProductId = null

    handleProductSelect(event) {
        let recordid = event.detail.recordId;

    }

    @track displayInfo = {
        primaryField: 'Name',
        additionalFields: ['ProductCode'],
    }

    pcfilter = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true,
            }
        ],
    }

    @track fcfilter = {
        criteria: [
            {
                fieldPath: 'ProductId__c',
                operator: 'eq',
                value: this.selectedProducitId
            }

        ],
    };

    recordChangeHandler(event) {
        debugger;
        let tt = event.detail.recordId
        this.selectedProductId = event.detail.recordId;
        this.selectedProducitId = this.selectedProductId
        let objectname = event.target.name;
        if (objectname == 'product') {
            this.failureCode.causalProductCode=tt
            this.isDisabledFC=false
            this.isDisabledFC=(tt=='' || tt == undefined || tt == null);
        } else if (objectname == 'failurecode') {

        }

       console.log(JSON.stringify(this.fcfilter));
    }

    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        // additionalFields: [{ fieldPath: 'Productcode' }],
    };

    handleSearchChange(event){
        debugger;
        let searchKey = event.target.value
        this.searchKey=searchKey;
        this.handleSearch(searchKey,this.selectedProductId);
        this.failureCode.failureCode=this.searchKey;
    }

    handleSearch(searchKey,productid) {
       debugger;
        if (searchKey.length >= 2) { // search after 2+ chars
            searchFailureCodes({ searchKey:searchKey,productid:productid})
                .then(result => {
                    this.records = result;
                })
                .catch(error => {
                    console.error(error);
                });
        } else {
            this.records = null;
        }
    }

    handleSelect(event) {
        debugger;
        const recId = event.currentTarget.dataset.id;
        this.selectedRecord = this.records.find(r => r.Id === recId);
        this.records = null; // hide dropdown after select
        if(this.selectedRecord.Name.length>3){
            this.searchKey=this.selectedRecord.Name;
        }
        this.failureCode.failureCode=this.searchKey;
        
    }
    get isSaveDisabled() {
        return this.isLoading || !this.failureCode.failureCode || !this.failureCode.causalProductCode;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        this.failureCode = {
            ...this.failureCode,
            [field]: value,
            isDuplicate: false,
            rowClass: ''
        };

        if (field === "vinCutoff") {
            if (!this.validateVin(value)) {
                event.target.setCustomValidity("VIN Cutoff must be empty or exactly 17 valid characters");
            } else {
                event.target.setCustomValidity("");
            }
            event.target.reportValidity();
        }

        // Clear previous results when user starts editing
        this.hasResults = false;
    }

    validateVin(vin) {
        // Allow empty OR exactly 17 alphanumeric (excluding I, O, Q as per VIN standard)
        const vinRegex = /^(?:[A-HJ-NPR-Z0-9]{17}|)$/;
        return vinRegex.test(vin);
    }

    async handleValidate() {
        debugger;
        // Check required fields
        if (!this.failureCode.failureCode || !this.failureCode.causalProductCode) {
            this.showNotification('Validation Error', 'Failure Code and Causal Product Code are required', 'error');
            return;
        }
        this.isLoading = true;
        try {
            const validationResult = await validateInputs({
                fcName: this.failureCode.failureCode,
                productcode: this.failureCode.causalProductCode,
                newVINCutOff: this.failureCode.vinCutoff
            });

            console.log(JSON.stringify('validationResult', validationResult));
            this.messages = validationResult;
            this.hasResults = true;

            if (validationResult.isSuccess) {
                this.showNotification('Validation Success', validationResult.message, 'success');

                this.DisabledhandleSave = false;

            } else {
                this.showNotification('Validation Error', validationResult.message, 'error');
            }
        } catch (error) {
            this.showNotification('Error', error.body?.message || 'An error occurred during validation', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleSave() {
        debugger;
        // Validate inputs first
        const inputs = this.template.querySelectorAll('lightning-input');
        let allValid = true;

        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                allValid = false;
            }
        });

        if (!allValid) {
            this.showNotification('Validation Error', 'Please fix all validation errors before saving', 'error');
            return;
        }

        this.isLoading = true;
        if (this.failureCode.batchSize == '') {
            this.failureCode.batchSize = null
        }

        try {
            const result = await createPostVINFCPCVIN({
                fcName: this.failureCode.failureCode,
                productcode: this.failureCode.causalProductCode,
                newVINCutOff: this.failureCode.vinCutoff,
                batchSize: this.failureCode.batchSize
            });

            this.messages = result;
            this.hasResults = true;

            if (result.isSuccess) {
                console.log(JSON.stringify('result', result));
                this.showNotification('Success', result.message, 'success');
                if (result.recordId) {
                    this.failureCodeRecordId = result.recordId;
                    // alert(result.recordId);
                }
                // this.resetForm();
                this.hasResults = false;
                // this.isShowLaborCodeComponent = true;
            } else {
                console.log(JSON.stringify('result', result));
                this.showNotification('Error', result.message, 'error');
            }
        } catch (error) {
            this.showNotification('Error', error.body?.message || 'An error occurred while saving', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.resetForm();
        this.hasResults = false;
    }

    resetForm() {
        this.failureCode = {
            failureCode: '',
            batchSize: '',
            active: true,
            causalProductCode: '',
            vinCutoff: '',
            isDuplicate: false,
            rowClass: ''
        };
    }

    showNotification(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    get notificationClass() {
        return `${this.messages.isSuccess ? 'slds-theme_success slds-theme_alert-texture slds-box' : 'slds-theme_warning slds-theme_alert-texture slds-box'}`;
    }
}