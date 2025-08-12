import { LightningElement, api, wire, track } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';
import ID_FIELD from '@salesforce/schema/WorkOrder.Id';

const FIELDS = [STATUS_FIELD];

const ACTION_PLAN_WITH_STATUS = gql`
  query GetActionPlans($jobCardId: ID!) {
    uiapi {
      query {
        ActionPlan(where: { Job_Card__c: { eq: $jobCardId } }) {
          edges {
            node {
              Id
              Field_Fix__r {
                Status__c {
                  value
                }
              }
              To_be_Completed_in_JC__c {
                value
              }
            }
          }
        }
      }
    }
  }
`;

export default class WorkOrderStatusPath extends LightningElement {
    @api recordId;
    @track actionPlans = [];
    @track hasPendingStatus = false;
    @track currentStatus;
    @track selectedStep;
    @track showModal = false;
    @track isCanceledPath = false;
    @track computedSteps = [];

    // Define all status options
    statusOptions = {
        base: [
            { label: 'New', value: 'New' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Re-Work', value: 'Re-Work' },
            { label: 'On Hold', value: 'On Hold' },
            { label: 'Ready for Delivery', value: 'Ready for Delivery' },
            { label: 'Final Status', value: 'Final Status' }
        ],
        withPending: [
            { label: 'New', value: 'New' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Re-Work', value: 'Re-Work' },
            { label: 'On Hold', value: 'On Hold' },
            { label: 'Submit For Approval', value: 'Submit For Approval' },
            { label: 'Ready for Delivery', value: 'Ready for Delivery' },
            { label: 'Final Status', value: 'Final Status' }
        ],
        completed: [
            { label: 'New', value: 'New' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Re-Work', value: 'Re-Work' },
            { label: 'On Hold', value: 'On Hold' },
            { label: 'Ready for Delivery', value: 'Ready for Delivery' },
            // { label: 'Submit For Approval', value: 'Submit For Approval' },
            { label: 'Completed', value: 'Completed' }
        ],
        canceled: [
            { label: 'New', value: 'New' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Re-Work', value: 'Re-Work' },
            { label: 'On Hold', value: 'On Hold' },
            { label: 'Submit For Approval', value: 'Submit For Approval' },
            { label: 'Cancellation Requested', value: 'Cancellation Requested' },
            { label: 'Canceled', value: 'Canceled' }
        ],
        final: [
            { label: 'Completed', value: 'Completed' },
            { label: 'Cancellation Requested', value: 'Cancellation Requested' },
            { label: 'Canceled', value: 'Canceled' }
        ]
    };

    // Compute steps with classes
    computeSteps() {
        let steps = [];
        if (this.currentStatus === 'Completed') {
            steps = [...this.statusOptions.completed];
        }
        else if (this.currentStatus === 'Canceled' || this.currentStatus === 'Cancellation Requested') {
            this.isCanceledPath = true;
            steps = [...this.statusOptions.canceled];
        }
        else {
            steps = this.hasPendingStatus ?
                [...this.statusOptions.withPending] :
                [...this.statusOptions.base];
        }

        // Add classes to each step
        this.computedSteps = steps.map(step => {
            let stepClass = '';

            // Add active class if step is selected
            if (step.value === this.selectedStep) {
                stepClass += 'slds-is-active ';
            }

            // Add completed/canceled classes
            if (step.value === 'Completed') {
                stepClass += 'slds-is-completed ';
            }
            else if (step.value === 'Cancellation Requested' || step.value === 'Canceled') {
                stepClass += 'slds-has-error ';
            }

            return {
                ...step,
                stepClass: stepClass.trim()
            };
        });
    }

    get isFinalStatus() {
        // return [
        //     'Completed',
        //     'Canceled',
        //     'Cancellation Requested'
        // ].includes(this.currentStatus);
    }

    get footerButtonLabel() {
        return this.selectedStep === 'Final Status' ?
            'Select Final Status' :
            'Mark Stage as Complete';
    }

    @wire(graphql, {
        query: ACTION_PLAN_WITH_STATUS,
        variables: "$variables"
    })
    wiredActionPlans({ data, errors }) {
        if (data) {
            this.actionPlans = data.uiapi.query.ActionPlan?.edges.map(edge => ({
                Id: edge.node.Id,
                FieldFixStatus: edge.node.Field_Fix__r?.Status__c?.value,
                IsCompleted: edge.node.To_be_Completed_in_JC__c?.value
            })) || [];

            // Check for incomplete action plans
            this.hasPendingStatus = this.actionPlans.some(
                plan => plan.IsCompleted === false
            );

            this.computeSteps();
        }
        if (errors) {
            console.error('GraphQL errors:', errors);
            this.showToast('Error', 'Failed to load action plans', 'error');
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredWorkOrder({ data, error }) {
        if (data) {
            this.currentStatus = data.fields.Status.value;
            this.selectedStep = this.currentStatus;

            // Set canceled path flag
            this.isCanceledPath = ['Canceled', 'Cancellation Requested'].includes(this.currentStatus);
            this.computeSteps();
        }
        else if (error) {
            this.showToast('Error', 'Failed to fetch status', 'error');
        }
    }

    get variables() {
        return { jobCardId: this.recordId };
    }

    handleStepClick(event) {
        const stepValue = event.currentTarget.dataset.value;
        if (!this.isFinalStatus) {
            this.selectedStep = stepValue;
            this.computeSteps();
        }
    }

    openModal(event) {
        debugger;
        const lable = event.currentTarget.label;
        if (lable == 'Mark Stage as Complete') {
            this.handleSave();
        } else {
            this.showModal = true;
        }

    }

    closeModal() {
        this.showModal = false;
    }

    handleStatusChange(event) {
        this.selectedStep = event.detail.value;
    }

    handleSave() {
        debugger;
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = this.selectedStep;

        updateRecord({ fields })
            .then(() => {
                this.currentStatus = this.selectedStep;
                this.showModal = false;
                this.showToast('Success', 'Status updated successfully', 'success');

                // Update canceled path flag
                this.isCanceledPath = ['Canceled', 'Cancellation Requested'].includes(this.selectedStep);
                this.computeSteps();
            })
            .catch(error => {
                let errorMessage = 'Unknown error';
                // Try to parse structured error from GraphQL or Apex
                if (error && error.body && error.body.output) {
                    const { errors, fieldErrors } = error.body.output;
                    let messages = [];
                    // Collect general errors
                    if (errors && errors.length > 0) {
                        messages = messages.concat(errors.map(e => e.message));
                    }
                    // Collect field-specific errors
                    if (fieldErrors) {
                        for (let field in fieldErrors) {
                            messages = messages.concat(fieldErrors[field].map(e => e.message));
                        }
                    }
                    errorMessage = messages.join('; ');
                }
                this.showToast('Error', errorMessage, 'error');
                console.error(errorMessage);
                
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}