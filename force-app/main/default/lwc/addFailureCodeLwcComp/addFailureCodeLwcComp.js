import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFailureCodeRecords from '@salesforce/apex/AddFailureCodeController.saveFailureCodeRecords';

export default class AddFailureCodeLwcComp extends LightningElement {
    @track failureCodes = [{
        id: 1,
        failureCode: '',
        batchSize: '',
        active: false,
        causalProductCode: '',
        vinCutoff: '',
        isDuplicate: false,
        rowClass: ''
    }];

    @track messages = [];   // store row-level results
    @track hasResults = false;

    nextId = 2;
    hasDuplicates = false;

    handleAddRow() {
        this.failureCodes = [
            ...this.failureCodes,
            {
                id: this.nextId++,
                failureCode: '',
                batchSize: '',
                active: false,
                causalProductCode: '',
                vinCutoff: '',
                isDuplicate: false,
                rowClass: ''
            }
        ];

        this.checkForDuplicates();
    }

    handleDeleteRow(event) {
        const rowId = event.target.dataset.id;
        this.failureCodes = this.failureCodes.filter(row => row.id != rowId);
        this.checkForDuplicates();
    }

    handleInputChange(event) {
        debugger;
        const rowId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        this.failureCodes = this.failureCodes.map(row => {
            if (row.id == rowId) {
                return { ...row, [field]: value, isDuplicate: false, rowClass: '' };
            }
            return row;
        });

        setTimeout(() => this.checkForDuplicates(), 300);

        if (field === "vinCutoff") {
            if (!this.validateVin(value)) {
                event.target.setCustomValidity("VIN Cutoff must be empty or exactly 17 valid characters");
            } else {
                event.target.setCustomValidity("");
            }
            event.target.reportValidity();
        }

        // Update your row object or whatever logic you need
        // let row = this.failureCodes.find(item => item.id == rowId);
        // if (row) {
        //     row[field] = value;
        // }
    }

    validateVin(vin) {
    // Allow empty OR exactly 17 alphanumeric (excluding I, O, Q as per VIN standard)
    const vinRegex = /^(?:[A-HJ-NPR-Z0-9]{17}|)$/;

    return vinRegex.test(vin);
}

    // Duplicate check with rowClass update
    checkForDuplicates() {
        let hasDupes = false;
        let seenKeys = new Set();

        // Reset duplicates
        this.failureCodes = this.failureCodes.map(row => ({
            ...row,
            isDuplicate: false,
            rowClass: ''
        }));

        this.failureCodes.forEach(row => {
            if (!row.failureCode || !row.causalProductCode) return;

            const vin = row.vinCutoff?.trim() || null;
            const key = vin
                ? `${row.failureCode}|${row.causalProductCode}|${vin}`
                : `${row.failureCode}|${row.causalProductCode}`;

            if (seenKeys.has(key)) {
                hasDupes = true;

                // mark dupes
                this.failureCodes = this.failureCodes.map(r => {
                    if (r.id === row.id || this.getRowKey(r) === key) {
                        return { ...r, isDuplicate: true, rowClass: 'slds-theme_warning' };
                    }
                    return r;
                });
            } else {
                seenKeys.add(key);
            }
        });

        this.hasDuplicates = hasDupes;
    }

    getRowKey(row) {
        const vin = row.vinCutoff?.trim() || null;
        return vin
            ? `${row.failureCode}|${row.causalProductCode}|${vin}`
            : `${row.failureCode}|${row.causalProductCode}`;
    }

    // async handleSave() {
    //     const inputs = this.template.querySelectorAll('lightning-input');
    //     let allValid = true;

    //     inputs.forEach(input => {
    //         if (!input.checkValidity()) {
    //             input.reportValidity();
    //             allValid = false;
    //         }
    //     });

    //     if (!allValid) {
    //         return;
    //     }

    //     this.checkForDuplicates();
    //     if (this.hasDuplicates) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Validation Error',
    //                 message: 'Duplicate entries found. Please fix them before saving.',
    //                 variant: 'error'
    //             })
    //         );
    //         return;
    //     }

    //     const recordsToSave = this.failureCodes.map(row => ({
    //         sobjectType: 'Failure_Code__c',
    //         fName: row.failureCode,
    //         batchSize: row.batchSize,
    //         isActive: row.active,
    //         productCode: row.causalProductCode,
    //         vinCutOff: row.vinCutoff
    //     }));



    //     try {
    //         const data = await saveFailureCodeRecords({ fCodes: recordsToSave });
    //         console.log('data : ' + data);
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Success',
    //                 message: 'Failure Codes created successfully',
    //                 variant: 'success'
    //             })
    //         );

    //         this.resetTable();

    //     } catch (error) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Error',
    //                 message: error.body?.message || 'An error occurred while saving records',
    //                 variant: 'error'
    //             })
    //         );
    //     }
    // }


    async handleSave() {
        debugger;
        const inputs = this.template.querySelectorAll('lightning-input');
        let allValid = true;

        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                allValid = false;
            }
        });

        if (!allValid) {
            return;
        }

        this.checkForDuplicates();
        if (this.hasDuplicates) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: 'Duplicate entries found. Please fix them before saving.',
                    variant: 'error'
                })
            );
            return;
        }

        const recordsToSave = this.failureCodes.map(row => ({
            sobjectType: 'Failure_Code__c',
            fName: row.failureCode,
            batchSize: row.batchSize,
            isActive: row.active,
            productCode: row.causalProductCode,
            vinCutOff: row.vinCutoff
        }));

        try {
            const data = await saveFailureCodeRecords({ fCodes: recordsToSave });

            this.messages = data;   // store messages for UI table
            this.hasResults = true;

            // show toast for each record
            data.forEach(r => {
                let title = r.isSuccess ? 'Success' : 'Error';
                let message = r.message;
                let variant = r.isSuccess ? 'success' : 'error'
                this.showNotification(title, message, variant);
            });

            // reset table only if all rows are successful
            const allSuccessful = data.every(r => r.isSuccess);
            if (allSuccessful) {
                this.resetTable();
            }

        } catch (error) {
            let message = error.body?.message || 'An error occurred while saving records';
            this.showNotification('Error', message, 'error');
        }
    }


    handleCancel() {
        this.resetTable();
    }

    resetTable() {
        this.failureCodes = [{
            id: 1,
            failureCode: '',
            batchSize: '',
            active: false,
            causalProductCode: '',
            vinCutoff: '',
            isDuplicate: false,
            rowClass: ''
        }];
        this.nextId = 2;
        this.hasDuplicates = false;
    }

    showNotification(title, message, variant) {
        debugger
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}