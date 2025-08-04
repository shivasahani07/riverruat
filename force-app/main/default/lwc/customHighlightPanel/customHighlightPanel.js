import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getWeblinks from '@salesforce/apex/CustomHighlightPanelController.getWeblinks';
import { refreshApex } from '@salesforce/apex';

// Import schema fields
import WORK_ORDER_NUMBER_FIELD from '@salesforce/schema/WorkOrder.WorkOrderNumber';
import STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';
import JOB_TYPE_FIELD from '@salesforce/schema/WorkOrder.RR_Job_Type__c';
import OWNER_ID_FIELD from '@salesforce/schema/WorkOrder.OwnerId';
import CASE_ID_FIELD from '@salesforce/schema/WorkOrder.CaseId';
import START_DATE_FIELD from '@salesforce/schema/WorkOrder.StartDate';
import END_DATE_FIELD from '@salesforce/schema/WorkOrder.EndDate';

const FIELDS = [
    WORK_ORDER_NUMBER_FIELD,
    STATUS_FIELD,
    JOB_TYPE_FIELD
];

export default class CustomHighlightPanel extends NavigationMixin(LightningElement) {
    @api recordId;
    @track record = {};
    @track error;
    @track buttons = [];
    @track dropdownButtons = [];
    @track showCancelJobCard = false;
    @track isFlowAction = false;
    @track isLwcAction = false;
    @track componentConstructor;
    childProps = {};
    wiredRecordResult;
    @track headerSubject= 'Cancel Job Card'

    headerFields = [
        OWNER_ID_FIELD, 
        CASE_ID_FIELD, 
        STATUS_FIELD, 
        START_DATE_FIELD, 
        END_DATE_FIELD
    ];

    get inputFlowVariables() {
        return [{
            name: 'recordId',
            type: 'String',
            value: this.recordId
        }];
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            this.record = {
                WorkOrderNumber: data.fields.WorkOrderNumber.value,
                Status: data.fields.Status.value,
                RR_Job_Type__c: data.fields.RR_Job_Type__c?.value
            };
            this.fetchAllData();
            this.error = undefined;
        } else if (error) {
            this.record = undefined;
            this.error = error.body.message;
        }
    }

    fetchAllData() {
        getWeblinks({ 
            sobjectName: 'WorkOrder', 
            recordId: this.recordId 
        })
        .then(response => {
            if (response) {
                this.processButtons(response);
                this.processDropdownButtons();
            }
        })
        .catch(error => {
            this.error = error.body.message;
            console.error('Error in fetchAllData:', error);
        });
    }

    processButtons(response) {
        const buttonData = response.buttons || [];
        const apexPageURL = response.apexPageURL || {};

        this.buttons = buttonData.map(item => ({
            ...item,
            apexPageURL: apexPageURL[item.ScontrolId],
            isVisible: this.shouldShowButton(item)
        }));

        // Add LWC actions with status filtering
        this.addLwcActions();
    }

    shouldShowButton(button) {
        const { Status, RR_Job_Type__c } = this.record;
        const buttonName = button.Name;

        if (Status === 'Ready for Delivery') {
            if (['Generate_Invoice', 'Generate_Insurance_Invoice'].includes(buttonName)) return false;
            if (buttonName === 'Generate_Pre_Insurance_Invoice' && RR_Job_Type__c !== 'Accidental') return false;
        } 
        else if (Status === 'Completed') {
            if (['Generate_Pre_Invoice', 'Generate_Pre_Insurance_Invoice'].includes(buttonName)) return false;
            if (buttonName === 'Generate_Insurance_Invoice' && RR_Job_Type__c !== 'Accidental') return false;
        } 
        else {
            if ([
                'Generate_Invoice', 
                'Generate_Insurance_Invoice', 
                'Generate_Pre_Invoice', 
                'Generate_Pre_Insurance_Invoice'
            ].includes(buttonName)) return false;
        }
        return true;
    }

    // NEW: Status-based LWC action definitions
    addLwcActions() {
        const lwcActions = [
            {
                seq: 1,
                Name: 'JobCardActionPlanApproval',
                MasterLabel: 'Submit For Approval',
                type: 'lwc',
                status: ['Ready for Delivery'] // Only show for this status
            },
            // {
            //     seq: 2,
            //     Name: 'TestLwcComponent',
            //     MasterLabel: 'Test LWC',
            //     type: 'lwc',
            //     // status: ['Ready for Delivery', 'Completed'] // Show for these statuses
            // }
        ];

        // Filter actions based on current status
        const visibleLwcActions = lwcActions.map(action => {
            return {
                ...action,
                isVisible: action.status.includes(this.record.Status)
            };
        });

        this.buttons = [...this.buttons, ...visibleLwcActions];
    }

    processDropdownButtons() {
        this.dropdownButtons = [
            { id: 'Edit', label: 'Edit', value: 'Edit' },
            { id: 'Delete', label: 'Delete', value: 'Delete' }
        ];

        if (this.record.Status !== 'Completed') {
            this.dropdownButtons.unshift({
                id: 'RR_Cancel_Job_Card',
                label: 'Cancel Job Card',
                value: 'RR_Cancel_Job_Card',
            });
        }
    }

    handleMenuSelect(event) {
        const action = event.detail.value;
        const actions = {
            'Edit': () => this.handleEdit(),
            'Delete': () => this.handleDelete(),
            'RR_Cancel_Job_Card': () => this.openCancelJobCard()
        };
        
        if (actions[action]) actions[action]();
    }

    handleButtonClick(event) {
        const dataset = event.currentTarget.dataset;
        const type = dataset.type;
        const name = dataset.name;
        const pageURL = dataset.page;

        if (type === 'flow') {
            this.openCancelJobCard();
        } 
        else if (type === 'lwc') {
            this.headerSubject='Submit For Action Plan Approval'
            this.openLwcComponent(name);
        } 
        else if (pageURL) {
            window.open(pageURL, '_blank');
        }
    }

    handleEdit() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'edit'
            }
        });
    }

    handleDelete() {
        deleteRecord(this.recordId)
            .then(() => {
                this.showToast('Success', 'Record deleted', 'success');
                this.navigateToWorkOrderHome();
            })
            .catch(error => {
                this.showToast('Error deleting record', error.body.message, 'error');
            });
    }

    navigateToWorkOrderHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WorkOrder',
                actionName: 'home'
            }
        });
    }

    openCancelJobCard() {
        this.showCancelJobCard = true;
        this.isFlowAction = true;
        this.isLwcAction = false;
    }

    openLwcComponent(componentName) {
        this.childProps = { 
            recordId: this.recordId,
            customRecId: this.recordId
        };
        this.showCancelJobCard = true;
        this.isLwcAction = true;
        this.isFlowAction = false;
        this.loadComponent(componentName);
    }

    closeCancelJobCard() {
        this.showCancelJobCard = false;
        this.isFlowAction = false;
        this.isLwcAction = false;
        this.componentConstructor = undefined;
        refreshApex(this.wiredRecordResult);
        this.headerSubject='Cancel Job Card';
    }

    async loadComponent(componentName) {
        try {
            const module = await import(`c/${componentName}`);
            this.componentConstructor = module.default;
        } catch (error) {
            console.error('Error loading component:', error);
            this.showToast('Error', `Component ${componentName} not found`, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}