import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedWorkPlans from '@salesforce/apex/WorkPlanController.getRelatedWorkPlans';
import deleteWorkPlanApex from '@salesforce/apex/WorkPlanController.deleteWorkPlanApex';
import getLabourCode from '@salesforce/apex/AdditionalJobsRecommendedController.getLabourCode';
import getWarrantyForJobCard from '@salesforce/apex/WorkOrderLineItemController.getWarrantyForJobCard';
import { RefreshEvent } from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from "lightning/uiRecordApi";
import Status from "@salesforce/schema/WorkOrder.Status";



export default class BulkInsertWorkPlans extends NavigationMixin(LightningElement) {
    @api recordId;
    keyIndex = 0;
    showProducts = true;
    showSubmitButton = true;
    showAddMoreButton = false;
    @track existingWorkPlans = [];
    @track submittedWorkPlans = [];
    @track name = '';
    @track addMoreDis = false;
    @track itemList = [
        {
            id: 0,
            code: ''
        }
    ];

    @track showAll;
    @track showRow = false;
    @track IsInsurance = false;
    

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [Status],
    })
    wiredWorkOrder({ error, data }) {
        if (data) {
            const status = data.fields.Status.value;

            const blockedStatuses = new Set([
                'Ready for Delivery',
                'Submit For Approval',
                'Cancellation Requested',
                'Canceled',
                'Completed'
            ]);

            if (blockedStatuses.has(status)) {
                this.showAll = false;
                this.addMoreDis = true;
            } else {
                this.showAll = true;
                this.addMoreDis = false;
            }
        }

        if (error) {
            console.error('Error fetching record:', error);
        }
    }


    toggleTemplates() {
        this.showAll = !this.showAll;
        this.showRow = !this.showRow;
    }
    // Columns definition for Lightning Datatable
    columns = [
        {
            label: 'Name',
            fieldName: 'jobUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' },
            sortable: true
        },
        {
            label: 'Labour Code',
            fieldName: 'codeUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'RR_Labour_Code__c' }, target: '_blank' },
            sortable: true
        },
        {
            label: 'Efforts (Hours)',
            fieldName: 'RR_Efforts_Hours__c',  // Remove extra space
            type: 'number'
        },
        {
            label: 'Efforts (Minutes)',
            fieldName: 'RR_Efforts_Minutes__c', // Remove extra space
            type: 'number'
        },
        {
            label: 'Labour Category',
            fieldName: 'RR_Labour_Category__c',
            type: 'text'
        },
        {
            label: 'Labour Charge',
            fieldName: 'computedCharge',
            type: 'number'
        },
        {
            label: 'Total Labour charge',
            fieldName: 'Total_Labour_Cost__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        }
    ];

    filteredReplacementTypeOptions = [
        { label: 'Paid', value: 'Paid' },
        { label: 'None', value: 'None' },
        { label: 'River Warranty', value: 'River Warranty' },
        { label: 'Insurance', value: 'Insurance' },
        { label: 'EW(Extended Warranty)', value: 'EW(Extended Warranty)' },
        { label: 'Goodwill Warranty', value: 'Goodwill Warranty' },
       
    ];


    refreshResultData;

    connectedCallback() {
        debugger;
        this.fetchWarranty();
    }

    handleRowAction(event) {
        debugger;
        const actionName = event.detail.action.name;
        const rowId = event.detail.row.jobUrl.split("/")[1];
        console.log('Action Name==>', actionName);
        console.log('rowId===>', rowId);

        if (actionName === 'delete') {
            this.deleteWorkPlan(rowId);
        }
    }
    deleteWorkPlan(rowId) {
        debugger;
        deleteWorkPlanApex({ rowId: rowId })
            .then(() => {
                this.showToast(true, 'Labour deleted successfully.');
                return refreshApex(this.refreshResultData);
            })
            .catch(error => {
                this.showToast(false, 'Error deleting part: ' + error.body.message);
            });
    }

    @wire(getRelatedWorkPlans, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        debugger;
        this.refreshResultData = result;
        if (result.data) {
            console.log('data received>>', result.data);
            this.existingWorkPlans = result.data.map(workPlan => {
                const jobUrl = `/${workPlan.Id}`;
                const codeUrl = workPlan.RR_Labour_Code__c ? `/${workPlan.RR_Labour_Code__c}` : '';
                const allowedStatuses = ['New', 'In Progress', 'Re-Work', 'On Hold'];
                const showDeleteButton = allowedStatuses.includes(workPlan.WorkOrder.Status);

                let computedCharge;
                if (workPlan.RR_Labour_Category__c === 'River Warranty') {
                    computedCharge = workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Labour_Charges__c : null;
                } else if (workPlan.RR_Labour_Category__c === 'Paid') {
                    computedCharge = workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Labour_Charge__c : null;
                }

                return {
                    Id: workPlan.Id,
                    Name: workPlan.Name,
                    RR_Labour_Code__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Code : '',
                    Status__c: workPlan.Status__c,
                    Duration_Min__c: workPlan.Duration_Min__c ? workPlan.Duration_Min__c : 0,
                    Duration_Hour__c: workPlan.Duration_Hour__c ? workPlan.Duration_Hour__c : 0,
                    Total_Labour_Cost__c: workPlan.Total_Labour_Cost__c,
                    RR_Labour_Category__c: workPlan.RR_Labour_Category__c,
                    RR_Efforts_Hours__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Efforts_Hours__c : 0,  // Ensure value is fetched
                    RR_Efforts_Minutes__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Efforts_Minutes__c : 0, // Ensure value is fetched
                    jobUrl: jobUrl,
                    codeUrl: codeUrl,
                    showDeleteButton: !showDeleteButton,
                    computedCharge: computedCharge  // Include the computed charge here
                };
            });
        } else if (result.error) {
            console.error('Error fetching Work Plans:', result.error);
        }
    }


    fetchWarranty() {
        getWarrantyForJobCard({ workOrderId: this.recordId })
            .then(result => {
                this.warrantyId = result.Id;
                console.log('---result', result)
                if (result.Status__c != 'Sumbit for Approval') {
                    this.showAll = true;
                } else {
                    this.showAll = false;
                }

                console.log('Fetched Warranty ID: ', this.warrantyId);
            })
            .catch(error => {
                console.error('Error fetching Warranty ID:', error);
            });
    }

    addRow(event, index) {
        debugger;
        index = parseInt(event.target.dataset.id, 10);
        console.log('indes os>>s', JSON.stringify(event.target));
        ++this.keyIndex;
        let newItem = { id: this.keyIndex, code: '' };
        this.itemList.splice(index + 1, 0, newItem);
        console.log('Row added at index:', index + 1);
    }

    removeRow(event) {
        let index = parseInt(event.target.id, 10);
        if (this.itemList.length > 1) { // Ensure there is always at least one row
            this.itemList.splice(index, 1);
            console.log('Row deleted at index:', index);
        } else {
            console.log('Cannot delete the last row.');
        }
    }

    /*
    handleSubmit() {
        debugger;
        let isVal = true;
        this.template.querySelectorAll('lightning-input-field').forEach(element => {

            console.log('element>>' + element);
            isVal = isVal && element.reportValidity();
            console.log('isVal>>' + isVal);
        });



        if (isVal) {
            const forms = Array.from(this.template.querySelectorAll('lightning-record-edit-form'));
            forms.forEach(form => form.submit());
            // Refresh data after successful submission
            refreshApex(this.refreshResultData)
                .then(() => {
                    //this.showToast(true, 'Work Plans added successfully!');
                    this.showAll = true;
                    this.showRow = false;
                    this.clearRows();

                })
                .catch(error => {

                    this.showToast(false, 'Error in fetching fresh data!');
                });
        } else {

            console.error('Error while adding Work Plans:');

            this.showToast(false, 'Please check the validations!');
        }
    }
    */
    /*
    handleSubmit() {
        debugger;
        
        // let customToastShown = false;

        // console.log('Item List ==>', JSON.stringify(this.itemList));

        // this.template.querySelectorAll('lightning-input-field').forEach(element => {

        //     console.log('element>>' + element);
        //     this.isVal = this.isVal && element.reportValidity();
        //     console.log('isVal>>' + this.isVal);
        // });

        // // Custom validation for each item
        // this.itemList.forEach((item, idx) => {

        //     // Skip already invalid itemsshowToast
        //     if (item.hasError) {
        //         this.isVal = false;
        //     }

            
        //     console.log('Approved Insurance ==>'+ item.Approved_Insurance__c);
        //     // Approved Insurance validation
        //     if (item.IsInsurance && (item.Approved_Insurance__c == null || 
        //         item.Approved_Insurance__c < 0 || 
        //         item.Approved_Insurance__c > 100 || 
        //         isNaN(item.Approved_Insurance__c))) {

        //         this.isVal = false;
        //         customToastShown = true;
        //         item.hasError = true;
        //         this.showToast(false, 'Approved Insurance (%) must be between 0 and 100.');
        //         return;
        //     }
        // });

        // if(!this.checkValidity()){
        //     return;
        // }
        if (this.checkValidity()) {
            const forms = Array.from(this.template.querySelectorAll('lightning-record-edit-form'));
            forms.forEach(form => form.submit());
            // Refresh data after successful submission
            refreshApex(this.refreshResultData)
                .then(() => {
                    //this.showToast(true, 'Work Plans added successfully!');
                    this.showAll = true;
                    this.showRow = false;
                    this.clearRows();

                })
                .catch(error => {

                    this.showToast(false, 'Error in fetching fresh data!');
                });
         } //else {

        //     console.error('Error while adding Work Plans:');

        //     this.showToast(false, 'Please check the validations!');
        // }
    }

    checkValidity(){
        debugger;
        let isVal = true;
       let customToastShown = false;

        console.log('Item List ==>', JSON.stringify(this.itemList));

        this.template.querySelectorAll('lightning-input-field').forEach(element => {

            console.log('element>>' + element);
            isVal = isVal && element.reportValidity();
            console.log('isVal>>' + isVal);
        });

        // Custom validation for each item
        this.itemList.forEach((item, idx) => {

            // Skip already invalid itemsshowToast
            if (item.hasError) {
                isVal = false;
            }

            
            console.log('Approved Insurance ==>'+ item.Approved_Insurance__c);
            // Approved Insurance validation
            const approved = Number(item.Approved_Insurance__c);

            if (item.IsInsurance && (approved == null || 
                approved < 0 || 
                approved > 100 || 
                isNaN(approved))) {

                isVal = false;
                customToastShown = true;
                item.hasError = true;
                this.showToast(false, 'Approved Insurance (%) must be between 0 and 100.');
            
            }
        });
        console.log('this.isVal=====>',isVal);
        return isVal;

    }
    */
    

    handleInsuranceChange(event) {
        debugger;
        const index = parseInt(event.target.dataset.id, 10);
        const value = event.target.value;

        // Convert percentage input to decimal
        this.itemList[index].Approved_Insurance__c = value ? parseFloat(value) : null;
    }

    handleSubmit() {
        debugger;
        let isValid = true;
        let customToastShown = false;

        // Validate all lightning-input-fields (built-in validation)
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            isValid = isValid && element.reportValidity();
        });

        // Custom Approved Insurance validation
        if (this.itemList && this.itemList.length > 0) {
            this.itemList.forEach((item, index) => {
                const value = item.Approved_Insurance__c;
                console.log('value : ' + value);
                console.log('item.IsInsurance : ' + item.IsInsurance);

                if (item.IsInsurance && (value === null || isNaN(value) || value < 0 || value > 100)) {

                    isValid = false;
                    customToastShown = true;
                    this.showToast(false, 'Approved Insurance (%) must be between 0 and 100.');
                }
            });
        }

        if (!isValid) {
            // Stop form submission
            return;
        }

        // Convert percentage to decimal (only after validation passes)
        this.itemList = this.itemList.map(item => {
            if (item.Approved_Insurance__c != null && !isNaN(item.Approved_Insurance__c)) {
                item.Approved_Insurance__c = item.Approved_Insurance__c / 100;
            }
            return item;
        });

        // Submit all record edit forms
        this.template.querySelectorAll('lightning-record-edit-form').forEach(form => {
            form.submit();
        });

        // Refresh data after save
        refreshApex(this.refreshResultData)
            .then(() => {
                this.showToast(true, 'Records saved successfully!');
                this.showAll = true;
                this.showRow = false;
                this.clearRows();
            })
            .catch(error => {
                this.showToast(false, 'Error in fetching fresh data!');
            });
    }


    handleSuccess(event) {
        console.log('The success happed');
        this.showToast(true, 'Labour codes added successfully.');
        return refreshApex(this.refreshResultData);
    }

    handleError(event) {
        let errorMsg = '';

        console.log('Error:1', JSON.stringify(event.detail));

        if (event.detail && event.detail.output && event.detail.output.fieldErrors && event.detail.output.fieldErrors.length > 0) {
            console.log('inside 1');
            // Check for field-specific errors
            let fieldErrors = event.detail.output.fieldErrors;
            for (let fieldName in fieldErrors) {
                if (fieldErrors.hasOwnProperty(fieldName)) {
                    const fieldError = fieldErrors[fieldName];
                    if (fieldError && fieldError.length > 0) {
                        errorMsg = 'Error: ' + fieldError[0].message;
                        break; // Exit loop after finding the first field error
                    }
                }
            }
        } else if (event.detail && event.detail.output && event.detail.output.errors && event.detail.output.errors.length > 0) {
            console.log('inside 2');
            // Check for field-specific errors
            let fieldErrors = event.detail.output.errors;
            for (let fieldName in fieldErrors) {
                console.log(' error loccured1>>' + JSON.stringify(fieldErrors[fieldName]));
                if (fieldErrors.hasOwnProperty(fieldName)) {
                    console.log(' error loccured2>>' + JSON.stringify(fieldErrors[fieldName]));
                    const fieldError = fieldErrors[fieldName];
                    if (fieldError && fieldError.length > 0) {
                        console.log(' error loccured3>>' + JSON.stringify(fieldErrors[fieldName]));
                        errorMsg = 'Error: ' + fieldError[0].message;
                        break; // Exit loop after finding the first field error
                    } else if (fieldError.message) {
                        errorMsg = 'Error: ' + fieldError.message;
                        break;
                    }
                }
            }
        }
        else if (event.detail && event.detail.detail) {
            console.log('inside 3');
            errorMsg = 'Error: ' + event.detail.detail;
        } else if (event.detail && event.detail.message) {
            console.log('inside 4');
            errorMsg = 'Error: ' + event.detail.message;
        }
        else if (event.detail && event.detail.output && event.detail.output.errors) {
            // Check for Apex errors
            const apexErrors = event.detail.output.errors;
            if (apexErrors && apexErrors.length > 0) {
                errorMsg = 'Apex Error: ' + apexErrors[0].message;
            }
        } else {
            // Default generic error message
            errorMsg = 'An unknown error occurred. Please try again.';
        }

        // Display the error message in a single toast
        this.showToast(false, errorMsg);
    }

    handleAddMore() {
        // Clear the itemList
        this.itemList = [];
        this.clearRows(); // Clear rows when Add More is clicked


        // Add a new record with an incremented id
        let newId = this.keyIndex + 1;
        let newItem = { id: newId, code: '' };
        this.itemList.push(newItem);

        // Update keyIndex and button visibility
        this.keyIndex = newId;
        this.showSubmitButton = true;
        this.showAddMoreButton = false;
    }

    handleWrarrantyType(event) {
    debugger;
    const selectedValue = event.detail.value;
    const index = event.target.dataset.id;
    const fieldName = event.target.dataset.fieldname;

    if (this.itemList && this.itemList[index]) {
        // Update the field value in itemList
        this.itemList[index][fieldName] = selectedValue;

        // Show the insurance field only if Labour Category is "Insurance"
        if (fieldName === 'RR_Labour_Category__c') {
            this.itemList[index].showInsuranceField = (selectedValue === 'Insurance');

            if (selectedValue === 'Insurance') {
                this.itemList[index].IsInsurance = true;

            } else if(selectedValue !== 'Insurance'){
                this.itemList[index].IsInsurance = false;
            }

            // Reset the insurance field value if not Insurance
            if (!this.itemList[index].showInsuranceField) {
                this.itemList[index].Approved_Insurance__c = null;
            }
        }
    }

    // Update the hidden lightning-input-field if it exists
    const hiddenInput = this.template.querySelector(
        `lightning-input-field[data-id="${index}"][data-fieldname="${fieldName}"]`
    );
    if (hiddenInput) {
        hiddenInput.value = selectedValue;
    }

    // Trigger reactivity so UI updates
    this.itemList = [...this.itemList];
}





    handleCodeselection(event) {
        console.log('event.target.dataset.id', event.target.dataset.id);
        console.log('event.target.name', event.target.name);
        console.log('event.target.value', event.target.value);
        const index = event.target.dataset.id; // Assuming this dataset.id corresponds to the index of the itemList

        const codeId = event.target.value;

        if (!codeId) {
            // If the input field is cleared, reset the corresponding values
            this.itemList[index].labourCode = '';
            this.itemList[index].CodeDescription = '';
        } else {
            getLabourCode({ codeId: codeId })
                .then(result => {
                    console.log('code:', result);
                    // Update the item with dynamic values
                    if (result) {

                        this.itemList[index].name = result.Name;
                        //this.name = result.Name;

                        // Update each field independently if they exist
                        if (result.labourCode !== undefined) {
                            this.itemList[index].labourCode = result.labourCode;
                        }
                        if (result.labourCodeDescription !== undefined) {
                            this.itemList[index].CodeDescription = result.labourCodeDescription;
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching code values:', error);
                });
        }
    }


    clearRows() {
        this.itemList = [];
        this.keyIndex = 0;
        let newItem = { id: this.keyIndex, labourCode: '', labourCodeDescription: '' };
        this.itemList = [...this.itemList, newItem];
    }

    showToast(isSuccess, message) {
        let event;
        if (isSuccess) {
            event = new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success',
            });
        } else {
            event = new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
            });
        }
        this.dispatchEvent(event);
    }


}