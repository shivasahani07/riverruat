import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getRelatedWorkPlans from '@salesforce/apex/WorkPlanController.getRelatedWorkPlans';
import deleteWorkPlanApex from '@salesforce/apex/WorkPlanController.deleteWorkPlanApex';
import insertWorkPlans from '@salesforce/apex/WorkPlanController.insertWorkPlans';
import getLabourCode from '@salesforce/apex/AdditionalJobsRecommendedController.getLabourCode';
import VeripartWithActionWithPlanApex from '@salesforce/apex/TFRManagement.VeripartWithActionWithPlanApex';
import getFailureCode from '@salesforce/apex/AddFailureCodeController.getFailureCode';
import checkTFRValidation from '@salesforce/apex/TFRManagement.checkTFRValidation';

import { getRecord } from "lightning/uiRecordApi";
import getFailureCodeUpdated from '@salesforce/apex/AddFailureCodeController.getFailureCodeUpdated';
const STATUS_FIELD = 'WorkOrder.Status';
const VIN_FIELD = 'WorkOrder.Vehicle_Identification_Number__c';
const BLOCKED_STATUSES = new Set([
    'Ready for Delivery',
    'Submit For Approval',
    'Cancellation Requested',
    'Canceled',
    'Completed'
]);
const EDITABLE_STATUSES = new Set(['New', 'In Progress', 'Re work']);
const WARRANTY_PRIOR_APPLICABLE = new Set(['River Warranty', 'Paid', 'Parts Warranty']);
export default class BulkInsertWorkPlansCustom extends LightningElement {
    @api recordId;
    @track existingWorkPlans = [];
    @track itemList = [{ id: 0 }];
    @track showAll = true;
    @track showRow = false;
    @track addMoreDis = false;
    @track isLoading = false;
    @track isSubmitting = false;
    @track currentVinNo;
    @track ActionPlanProducts = [];
    @track ActionPlanlabours = [];
    keyIndex = 0;

    // Columns for the datatable
    columns = [
        {
            label: 'Labour Name', fieldName: 'partUrl', type: 'url', typeAttributes: { label: { fieldName: 'displayName' }, target: '_blank' },
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Labour Code',
            fieldName: 'RR_Labour_Code__c',
            type: 'text',
            sortable: true
        },
        // {
        //     label: 'Failure Code',
        //     fieldName: 'Failure_Code__c',
        //     type: 'text',
        //     sortable: true
        // },
        {
            label: 'Efforts (Hours)',
            fieldName: 'RR_Efforts_Hours__c',
            type: 'number',
            sortable: true,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Efforts (Minutes)',
            fieldName: 'RR_Efforts_Minutes__c',
            type: 'number',
            sortable: true,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Labour Category',
            fieldName: 'RR_Labour_Category__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Labour Charge',
            fieldName: 'computedCharge',
            type: 'currency',
            sortable: true,
            typeAttributes: { currencyCode: 'USD' },
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Total Labour charge',
            fieldName: 'Total_Labour_Cost__c',
            type: 'currency',
            sortable: true,
            typeAttributes: { currencyCode: 'USD' },
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'TFR Status',
            fieldName: 'tfrMessage',
            type: 'text',
            cellAttributes: { 
                class: { 
                    fieldName: 'tfrStatusClass' 
                } 
            }
        }
    ];

    // Labour category options
    filteredReplacementTypeOptions = [
        { label: 'Paid', value: 'Paid' },
        { label: 'None', value: 'None' },
        { label: 'River Warranty', value: 'River Warranty' },
        { label: 'Insurance', value: 'Insurance' },
        { label: 'EW(Extended Warranty)', value: 'EW(Extended Warranty)' },
        { label: 'Goodwill Warranty', value: 'Goodwill Warranty' }
    ];


      @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD, VIN_FIELD] })
        wiredWorkOrder({ error, data }) {
            if (data) {
                const status = data.fields.Status.value;
                this.currentVinNo = data.fields.Vehicle_Identification_Number__c.value;
                this.showAll = EDITABLE_STATUSES.has(status) && !BLOCKED_STATUSES.has(status);
                this.addMoreDis=!this.showAll;
            }
            if (error) this.handleError('Error loading work order status', error);
        }

    // Wire service to get existing work plans
    @wire(getRelatedWorkPlans, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        this.refreshResultData = result;
        this.isLoading = true;

        if (result.data) {
            this.existingWorkPlans = result.data.map(workPlan => {
                let computedCharge = 0;
                if (workPlan.RR_Labour_Category__c === 'River Warranty') {
                    computedCharge = workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Labour_Charges__c : 0;
                } else if (workPlan.RR_Labour_Category__c === 'Paid') {
                    computedCharge = workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Labour_Charge__c : 0;
                }

                return {
                    Id: workPlan.Id,
                    partUrl: `/${workPlan.Id}`,
                    rowClass: workPlan.RR_Labour_Code__r ? 'slds-text-color_weak' : '',
                    displayName: workPlan.Name,
                    RR_Labour_Code__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Code : '',
                    Failure_Code__c: workPlan.Failure_Code__r ? workPlan.Failure_Code__r.Name : '',
                    RR_Efforts_Hours__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Efforts_Hours__c : 0,
                    RR_Efforts_Minutes__c: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.RR_Efforts_Minutes__c : 0,
                    RR_Labour_Category__c: workPlan.RR_Labour_Category__c,
                    RR_Labour_CodeId: workPlan.RR_Labour_Code__r ? workPlan.RR_Labour_Code__r.Id : null,
                    computedCharge: computedCharge,
                    Total_Labour_Cost__c: workPlan.Total_Labour_Cost__c,
                    tfrMessage: workPlan.TFR_Required__c ? (workPlan.Post_Vin_cutt_off__c ? 'Post-VIN' : 'Pre-VIN') : 'No TFR',
                    tfrStatusClass: workPlan.TFR_Required__c ? 
                        (workPlan.Post_Vin_cutt_off__c ? 'post-vin-status' : 'pre-vin-status') : ''
                };
            });
            this.isLoading = false;
        } else if (result.error) {
            this.showToast('Error', 'Error fetching work plans: ' + result.error.body.message, 'error');
            this.isLoading = false;
        }
    }

    connectedCallback() {
        this.VeripartWithActionWithPlan(this.recordId);
       
    }

        // Refresh data
    refreshData() {
        this.isLoading = true;
        refreshApex(this.refreshResultData)
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Data refreshed successfully', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Error refreshing data: ' + error.body.message, 'error');
            });
    }

    // Toggle between showing the table and the form
    toggleTemplates() {
        this.showAll = !this.showAll;
        this.showRow = !this.showRow;
    }

    // Handle row actions in the datatable
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'delete') {
            this.deleteWorkPlan(row.Id);
        }
    }

    // Delete a work plan
    deleteWorkPlan(rowId) {
        deleteWorkPlanApex({ rowId: rowId })
            .then(() => {
                this.showToast('Success', 'Labour code deleted successfully', 'success');
                return refreshApex(this.refreshResultData);
            })
            .catch(error => {
                this.showToast('Error', 'Error deleting labour code: ' + error.body.message, 'error');
            });
    }

    // Add a new row to the form
    addNewRow() {
        this.keyIndex++;
        const newItem = { 
            id: this.keyIndex,
            RR_Labour_Code__c: '',
            RR_Labour_Category__c: '',
            LabourCharge: 0,
            Description: '',
            isFailureCodeVisible: false,
            failureCodeOptions: [],
            Failure_Code__c: '',
            TFR_Required__c: false,
            Post_Vin_cutt_off__c: false,
            tfrMessage: '',
            hasError: false,
            errorMessage: ''
        };
        this.itemList = [...this.itemList, newItem];
    }

    // Remove a row from the form
    removeRow(event) {
        debugger;
        const index = parseInt(event.target.dataset.id, 10);
        // this.itemList = this.itemList.filter((item, i) => i !== index);
        // if (this.itemList.length > 1) {
        //     // this.itemList = this.itemList.filter((item, i) => i !== index);
        // } else {
        //     this.showRow=false
        //     // this.showToast('Info', 'Cannot delete the only row', 'info');
        // }
    }

    get DisabledsubmitButtin() {
        return this.itemList.some(item => item.hasError);
    }

    // Handle labour code selection
    handleCodeselection(event) {
        debugger;
        const index = event.target.dataset.id;
        const value = event.detail.recordId;

        if(value==null){
            this.itemList[index].failureCodeOptions=null
            this.itemList[index].Failure_Code__c=null
            this.itemList[index].isFailureCodeVisible = false;
            return;
        }

        this.itemList[index].RR_Labour_Code__c = value;
        this.itemList[index].RR_Labour_CodeId = value;
        
        
        // Check for duplicates
        const rules = [
            { fields: ["RR_Labour_Category__c", "RR_Labour_CodeId"] }
        ];
        let tempMergedList = [...this.existingWorkPlans, ...this.itemList];
        let foundDuplucatesRecords = this.applyDuplicateRules(tempMergedList, rules);
        if (foundDuplucatesRecords.RR_Labour_Category__c_RR_Labour_CodeId.length > 0) {
            this.showError(index, 'You cannot repeat the same labour with the same categories');
            return;
        }
        
        if (this.checkActionPlansWithProducts(value)) {
            this.showError(index, 'Same labor found in Action Plans. Please check and update');
            return;
        }

        // Get labour code details
        getLabourCode({ codeId: value })
            .then(result => {
                this.itemList[index].LabourCharge = result.labourCharge || 0;
                this.itemList[index].Description = result.labourCodeDescription || 'Not Updated';
                this.itemList[index].Name = result.Name || 'Not Updated';
                
                // Check if this labour code requires TFR validation
                if (this.itemList[index].RR_Labour_Category__c === 'River Warranty') {
                    
                    // this.getFailureCodes(result.tfrEffectId, index);
                    this.getFailureCodes(value,index);
                }
                
                this.itemList = [...this.itemList];
            })
            .catch(error => {
                this.showToast('Error', 'Error fetching labour code details: ' + error.body.message, 'error');
            });
    }

    // Handle labour category selection
    handleWrarrantyType(event) {
        const index = event.target.dataset.id;
        const value = event.detail.value;

        this.itemList[index].RR_Labour_Category__c = value;
        
        // Show failure code field for River Warranty
        // this.itemList[index].isFailureCodeVisible = value === 'River Warranty';
        
        // Check for duplicates
        const rules = [
            { fields: ["RR_Labour_Category__c", "RR_Labour_CodeId"] }
        ];
        let tempMergedList = [...this.existingWorkPlans, ...this.itemList];
        let foundDuplucatesRecords = this.applyDuplicateRules(tempMergedList, rules);
        if (foundDuplucatesRecords.RR_Labour_Category__c_RR_Labour_CodeId.length > 0) {
            this.showError(index, 'You cannot repeat the same labour with the same categories');
            return;
        }
        
        this.itemList = [...this.itemList];
    }

    // Get failure codes for a TFR effect
    // async getFailureCodes(tfrEffectId, index) {
    //     debugger;
    //     try {
    //         const data = await getFailureCode({ tfrPEId: tfrEffectId, isLabour: true });

    //         this.itemList[index].failureCodeOptions = data.map(item => ({
    //             label: item.Name,
    //             value: item.Id
    //         }));
    //     } catch (error) {
    //         console.error('Error fetching failure codes: ', error);
    //     }
    // }

    // Handle failure code selection
    async handleFailureCodeChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const value = event.detail.value;
        
        this.itemList[index].Failure_Code__c = value;
        
        // Check TFR validation if we have a VIN
        if (this.currentVinNo) {
            await this.checkTFRApplicable(
                this.currentVinNo,
                this.itemList[index].Failure_Code__c,
                index,
                true // isLabour
            );
        } else {
            this.itemList[index].TFR_Required__c = false;
            this.itemList[index].Post_Vin_cutt_off__c = false;
            this.itemList[index].tfrMessage = 'No VIN available for validation';
        }
        
        this.itemList = [...this.itemList];
    }

    // Check TFR applicability
    async checkTFRApplicable(VINno, FailureCodeId, index, isLabour) {
        try {
            const returndata = await checkTFRValidation({ 
                VINno, 
                FailureCodeId,
                isLabour: isLabour
            });
            
            this.itemList[index].TFR_Required__c = returndata.isTFRApplicable;
            this.itemList[index].Post_Vin_cutt_off__c = returndata.isPostVinCuttoff;
            // {"isPostVinCuttoff":true,"isTFRApplicable":true,"message":"Post VIN year is newer"}'
            
            // Update UI based on TFR requirements
            this.updateTFRUI(index, returndata);
        }
        catch (error) {
            this.itemList[index].TFR_Required__c = false;
            this.itemList[index].Post_Vin_cutt_off__c = false;
            this.itemList[index].tfrMessage = 'Error during TFR validation';
            console.error('TFR Validation Error:', error);
        }
    }

    // Update UI based on TFR validation
    updateTFRUI(index, tfrData) {
        debugger;
        const item = this.itemList[index];
        
        if (tfrData.isTFRApplicable) {
            if (tfrData.isPostVinCuttoff) {
                item.tfrMessage = 'Post-VIN cutoff labour - special handling required';
                item.cssClass = item.cssClass ? item.cssClass + ' post-vin-row' : 'post-vin-row';
            } else if((tfrData.isPostVinCuttoff == undefined || tfrData.isPostVinCuttoff == null) && tfrData.isTFRApplicable){
                         item.tfrMessage = 'TFR is Required , special handling required';
                        item.cssClass = item.cssClass ? item.cssClass + 'post-vin-row' : 'post-vin-row';
            }else {
                item.tfrMessage = 'Pre-VIN cutoff labour - standard handling';
                item.cssClass = item.cssClass ? item.cssClass + ' pre-vin-row' : 'pre-vin-row';
            }
        } else {
            item.tfrMessage = 'No TFR requirements';
            item.cssClass = item.cssClass ? item.cssClass.replace(' post-vin-row', '').replace(' pre-vin-row', '') : '';
        }
        
        this.itemList[index] = {...item};
    }

    // Handle form submission
    handleSubmit() {
        // Validate form
        debugger;
        let isValid = true;
        const inputs = this.template.querySelectorAll('lightning-combobox, lightning-record-picker');
        inputs.forEach(input => {
            if (!input.value && input.required) {
                input.setCustomValidity('This field is required');
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        });

        if (!isValid) {
            this.showToast('Error', 'Please fill all required fields', 'error');
            return;
        }

        this.isSubmitting = true;

        // Prepare data for insertion
        const workPlansToInsert = this.itemList.map(item => {
            return {
                ParentRecordId: this.recordId,
                RR_Labour_Code__c: item.RR_Labour_Code__c,
                RR_Labour_Category__c: item.RR_Labour_Category__c,
                Failure_Code__c: item.Failure_Code__c,
                TFR_Required__c: item.TFR_Required__c,
                Post_Vin_cutt_off__c: item.Post_Vin_cutt_off__c,
                Name: item.Name
            };
        });

        // Call Apex to insert work plans
        insertWorkPlans({ workPlans: workPlansToInsert })
            .then(() => {
                this.showToast('Success', 'Labour codes added successfully', 'success');
                this.toggleTemplates();
                this.clearForm();
                this.refreshData();
                this.isSubmitting = false;
            })
            .catch(error => {
                this.showToast('Error', 'Error adding labour codes: ' + error.body.message, 'error');
                this.isSubmitting = false;
            });
    }

    // Clear the form
    clearForm() {
        this.itemList = [{ 
            id: 0,
            RR_Labour_Code__c: '',
            RR_Labour_Category__c: '',
            LabourCharge: 0,
            Description: '',
            isFailureCodeVisible: false,
            failureCodeOptions: [],
            Failure_Code__c: '',
            TFR_Required__c: false,
            Post_Vin_cutt_off__c: false,
            tfrMessage: '',
            hasError: false,
            errorMessage: ''
        }];
        this.keyIndex = 0;
    }

    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
        // alert(message);
    }

    VeripartWithActionWithPlan(workOrderId) {
        VeripartWithActionWithPlanApex({ workOrderId: workOrderId })
            .then(data => {
                this.ActionPlanProducts = data.RequiredProducts;
                this.ActionPlanlabours = data.RequiredLabours;
            })
            .catch(error => {
                console.error('Error in VeripartWithActionWithPlan:', error);
            });
    }

    checkActionPlansWithProducts(laborId) {
        return this.ActionPlanlabours.some(item => item.Code_Set__c === laborId);
    }

    showError(index, message) {
        this.itemList[index] = {
            ...this.itemList[index],
            hasError: true,
            errorMessage: message
        };
        this.itemList = [...this.itemList];
    }

    applyDuplicateRules(list, rules) {
        const results = {};
        for (const rule of rules) {
            const keyName = rule.fields.join("_");
            results[keyName] = this.findDuplicatesByFields(list, rule.fields);
        }
        return results;
    }

    findDuplicatesByFields(list, fields) {
        const seen = new Set();
        const duplicates = [];

        for (const item of list) {
            const key = fields.map(f => item[f]).join("|");
            if (seen.has(key)) {
                duplicates.push(item);
            } else {
                seen.add(key);
            }
        }
        return duplicates;
    }

    // NEW 
     async getFailureCodes(tfrPEId, index) {
        debugger;
        try {
            console.log('tfrPEId : ' + tfrPEId);
            const data = await getFailureCodeUpdated({ productId:tfrPEId, newVIN: this.currentVinNo }); // this.currentVinNo
            this.itemList[index].failureCodeOptions = data.map(item => ({
                label: item.Name,
                value: item.Id
            }));
            if(data.length>0)
            this.itemList[index].isFailureCodeVisible = true;
        } catch (error) {
            console.error('Error fetching failure codes: ', error);
        }
    }
}