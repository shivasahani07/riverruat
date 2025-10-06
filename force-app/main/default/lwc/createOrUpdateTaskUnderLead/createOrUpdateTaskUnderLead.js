import { LightningElement, api, wire, track } from 'lwc';
import getRecentCallTask from '@salesforce/apex/TaskLeadController.getRecentCallTask';
import handleTaskCompletion from '@salesforce/apex/TaskLeadController.handleTaskCompletion';
import getFieldDependencies from '@salesforce/apex/TaskLeadController.getFieldDependencies';
import leadThreshold from '@salesforce/apex/TaskLeadController.leadThreshold';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import Lead from '@salesforce/schema/Lead';
import Lost_Reason from '@salesforce/schema/Lead.Lost_Reason__c';


export default class CreateOrUpdateTaskUnderLead extends LightningElement {
    @api recordId;
    @track task;
    selectedStatus;
    selectedSubStatus;
    showDatePicker = false;
    callbackDueDate;
    disabledSub = true;
    showSpinner = false;
    optionsCategory;

    @track statusOptions = [];
    @track subStatusOptions = [];
    @track picklistAndDependentPicklist = {};
    @track selectedStatus;
    threshold = false;
    LostReason;
    LostReasonFeedback;

    @wire(getObjectInfo, { objectApiName: Lead })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Lost_Reason })
    wiredStatusData({ error, data }) {
        debugger;
        if (data) {
            this.optionsCategory = data.values;
        } else if (error) {
            console.error('Error in Industry picklist field', JSON.stringify(error));
        }
    }
    

    connectedCallback() {
        debugger;

        const url = window.location.href.toString();
        const queryParams = url.split("&");

        const recordIdParam = queryParams.find(param => param.includes("recordId"));

        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");

            if (recordIdKeyValue.length === 2) {
                this.recordId = recordIdKeyValue[1];
            } else {
                console.error("Invalid recordId parameter format");
            }
        } else {
            console.error("recordId parameter not found in the URL");
        }
        this.showSpinner = false;

        this.getCallLogsFromTask();
        this.getDependentPicklist();
        this.getLeadThreshold();
    }

    getLeadThreshold() {
        debugger;
        leadThreshold({recordId: this.recordId})
            .then(result => {
                if (result != null && result != undefined && result != '') {
                    if(result){
                        this.threshold = true;
                    }else{
                        this.threshold = false;
                    }
                    
                }
            })
            .catch(error => {
                console.log('Error ======>' + error);
            });
    }

    getCallLogsFromTask() {
        debugger;
        getRecentCallTask({leadId: this.recordId})
            .then(result => {
                if (result != null && result != undefined && result != '') {
                    this.task = { ...result };
                } else {
                    this.showToast('No Pending Task', 'No pending "Call" tasks found for this lead.', 'info');
                    this.closeModal();
                }
            })
            .catch(error => {
                console.log('Error ======>' + error);
            });
    }

    getDependentPicklist() {
        debugger;
        getFieldDependencies({ objectName: 'Task', controllingField: 'Status', dependentField: 'Sub_Status__c' })
            .then(result => {
                this.picklistAndDependentPicklist = result;
                if (this.picklistAndDependentPicklist) {
                    this.statusOptions = Object.keys(this.picklistAndDependentPicklist).map(key => {
                        return { label: key, value: key };
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching picklist dependencies:', error);
            });
    }

    handleStatusChange(event) {
        debugger;
        this.selectedStatus = event.detail.value;
        if (this.selectedStatus === 'Completed') {
            this.disabledSub = false;
            const dependentValues = this.picklistAndDependentPicklist[this.selectedStatus] || [];
            if (dependentValues) {
                this.subStatusOptions = dependentValues.map(item => ({
                    label: item,
                    value: item
                }));
            }
        }
    }

    handleSubStatusChange(event) {
        debugger;
        this.selectedSubStatus = event.detail.value;
        this.showDatePicker = (this.selectedSubStatus === 'Callback');
    }

    handleDateChange(event) {
        this.callbackDueDate = event.target.value;
    }

    handleChange(event){
        debugger;
        const inpName = event.target.name;
        if(inpName == 'LostFeedback'){
            this.LostReason = event.target.value;
        }
        if(inpName == 'LostFeedbackReason'){
            this.LostReasonFeedback = event.target.value;
        }

    }

    handleComplete() {
        debugger;
        if (!this.selectedStatus) {
            this.showToast('Missing Status', 'Please select a status', 'error');
            return;
        }

        if (!this.selectedSubStatus) {
            this.showToast('Missing Sub-Status', 'Please select a sub-status', 'error');
            return;
        }

        if (this.selectedSubStatus === 'Callback' && !this.callbackDueDate) {
            this.showToast('Missing Date', 'Please select a due date for Callback', 'error');
            return;
        }
        if(this.threshold == true){
            if(this.LostReason == null || this.LostReason == undefined || this.LostReason == ''){
                this.showToast('Missing Lost Reason', 'Please select a Lost Reason', 'error');
                 return;
            }
            if(this.LostReasonFeedback == null || this.LostReasonFeedback == undefined || this.LostReason == ''){
                this.showToast('Missing Lost Reason Feedback', 'Please provide Lost Reason Feedback', 'error');
                 return;
            }
            
        }

        try {
            handleTaskCompletion({
                taskId: this.task.Id, leadId: this.recordId, status: this.selectedStatus,
                subStatus: this.selectedSubStatus, dueDate: this.callbackDueDate, LostReason: this.LostReason, LostReasonFeedback: this.LostReasonFeedback
            });

            this.showToast('Success', 'Task completed successfully!', 'success');
            this.closeModal();
        } catch (error) {
            this.showToast('Error', 'Error completing task: ' + error.body.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}