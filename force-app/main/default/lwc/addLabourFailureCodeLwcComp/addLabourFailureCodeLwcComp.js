import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPostVINFCLabourVIN from '@salesforce/apex/AddLabourFailureCodeController.createPostVINFCLabourVIN';
import validateLabourInputs from '@salesforce/apex/AddLabourFailureCodeController.validateInputs';
import searchlabourFailureCodes from '@salesforce/apex/AddFailureCodeControllerNew.searchlabourFailureCodes';


export default class AddLabourFailureCodeLwcComp extends LightningElement {
    @track failureCode = {
        failureCode: '',
        batchSize: '',
        active: true,
        labourCode: '',
        vinCutoff: '',
        isDuplicate: false,
        rowClass: ''
    };
    @track DisabledhandleSave = true;
    @track messages = {};
    @track hasResults = false;
    @track isLoading = false;
    @track selectedProducitId = null
    @track searchKey = '';
    @track records;
    @track selectedRecord;
    @track selectedLabourcodesetid = null

     @track displayInfo = {
        primaryField: 'Name',
        additionalFields: ['Code'],
    }

    @track pcfilter = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true,
            }
        ],
    }


    handleSearch(searchKey, codesetid) {
        debugger;
        if (searchKey.length >= 2) { // search after 2+ chars
            searchlabourFailureCodes({ searchKey: searchKey, codesetid:codesetid})
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
    
    get recordsGetter() {
        debugger;
        return this.records ? this.records.length > 0 : false;
    }

    handleSelect(event) {
        debugger;
        const recId = event.currentTarget.dataset.id;
        this.selectedRecord = this.records.find(r => r.Id === recId);
        this.searchKey = this.selectedRecord.Name;
        this.records = null; // hide dropdown after select
        this.failureCode.failureCode = this.searchKey;   
    }

    recordChangeHandler(event) {
        debugger;
        this.selectedLabourcodesetid = event.detail.recordId;
        this.searchKey = '';
        this.records = null; // hide dropdown after select
        this.failureCode.labourCode=this.selectedLabourcodesetid
    }

    handleSearchChange(event) {
        debugger;
        let searchKey = event.target.value
        this.searchKey = searchKey;
        this.handleSearch(searchKey, this.selectedLabourcodesetid);
        this.failureCode.failureCode=this.searchKey;
    }



































    handleInputChange(event) {
        debugger
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
        debugger;
        // Allow empty OR exactly 17 alphanumeric (excluding I, O, Q as per VIN standard)
        const vinRegex = /^(?:[A-HJ-NPR-Z0-9]{17}|)$/;
        return vinRegex.test(vin);
    }

    async handleValidate() {
        debugger;
        // Check required fields
        if (!this.failureCode.failureCode || !this.failureCode.labourCode) {
            this.showNotification('Validation Error', 'Failure Code and Labour Code are required', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const validationResult = await validateLabourInputs({
                fcName: this.failureCode.failureCode,
                labourCode: this.failureCode.labourCode,
                newVINCutOff: this.failureCode.vinCutoff
            });

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

        try {
            const result = await createPostVINFCLabourVIN({
                fcName: this.failureCode.failureCode,
                labourCode: this.failureCode.labourCode,
                newVINCutOff: this.failureCode.vinCutoff,
                sampleRequired: this.failureCode.batchSize
            });

            this.messages = result;
            this.hasResults = true;

            if (result.isSuccess) {
                this.showNotification('Success', result.message, 'success');
                this.resetForm();
            } else {
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
            labourCode: '',
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

        // alert(message);
    }
}