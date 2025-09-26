import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createPostVINFCLabourVIN from '@salesforce/apex/AddLabourFailureCodeController.createPostVINFCLabourVIN';
import validateLabourInputs from '@salesforce/apex/AddLabourFailureCodeController.validateInputs';

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
                newVINCutOff: this.failureCode.vinCutoff
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

        alert(message);
    }
}