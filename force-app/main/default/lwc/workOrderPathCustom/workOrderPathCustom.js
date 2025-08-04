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
                Total_Job_Card_Completed__c {
                  value
                }
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
    actionPlans = [];
    hasPendingStatus = false;
    @track currentStatus;
    @track selectedStep;
    showModal = false;

    steps = [
        { label: 'New', value: 'New' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Re-Work', value: 'Re-Work' },
        { label: 'On Hold', value: 'On Hold' },
        // { label: 'Submit For Approval', value: 'Submit For Approval' },
        { label: 'Ready for Delivery', value: 'Ready for Delivery' },
        { label: 'Final Status', value: 'Final Status' }
    ];

    finalSteps = [
        { label: 'Completed', value: 'Completed' },
        { label: 'Cancellation Requested', value: 'Cancellation Requested' },
        { label: 'Canceled', value: 'Canceled' }
    ];

    completedStatus = [
        { label: 'New', value: 'New' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Re-Work', value: 'Re-Work' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Submit For Approval', value: 'Submit For Approval' },
        { label: 'Completed', value: 'Completed' }
    ];

    cancelStatus = [
        { label: 'New', value: 'New' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Re-Work', value: 'Re-Work' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Submit For Approval', value: 'Submit For Approval' },
        { label: 'Cancellation Requested', value: 'Cancellation Requested' },
        { label: 'Canceled', value: 'Canceled' }

    ];

    pendingActionPlans = [
        { label: 'New', value: 'New' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Re-Work', value: 'Re-Work' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Submit For Approval', value: 'Submit For Approval' },
        { label: 'Ready for Delivery', value: 'Ready for Delivery' },
        { label: 'Final Status', value: 'Final Status' }
    ]



    get displayedSteps() {
        debugger;
        if (this.currentStatus === 'Completed') {
            return this.completedStatus;
        } else if (this.currentStatus === 'Canceled' || this.currentStatus === 'Cancellation Requested') {
            return this.cancelStatus;
        }
        return this.steps;
    }

    get isFinalStatus() {
        debugger;
        return (
            this.currentStatus === 'Completed' ||
            this.currentStatus === 'Canceled' ||
            this.currentStatus === 'Cancellation Requested'
        );
    }

    get footerButtonLabel() {
        debugger;
        return this.isFinalStatus ? 'Change Final Status' : 'Select Final Status';
    }

    get statusOptions() {
        debugger;
        return this.finalSteps;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredWorkOrder({ data, error }) {
        if (data) {
            debugger;
            this.currentStatus = data.fields.Status.value;
            if (this.currentStatus == 'Completed') {
                this.completedStatus;
            } else if (this.currentStatus == 'Canceled') {

            }
            this.selectedStep = this.currentStatus;
        } else if (error) {
            this.showToast('Error', 'Failed to fetch status', 'error');
        }
    }

    @wire(graphql, {
        query: ACTION_PLAN_WITH_STATUS,
        variables: "$variables"
    })
    wiredActionPlans({ data, errors }) {
        this.isLoading = false;
        debugger;
        if (data) {
            this.actionPlans = data.uiapi.query.ActionPlan?.edges.map(edge => ({
                Id: edge.node.Id,
                FieldFixStatus: edge.node.Field_Fix__r?.Status__c?.value,
                IsCompleted: edge.node.To_be_Completed_in_JC__c?.value
            })) || [];

            // this.hasPendingStatus = this.actionPlans.some(
            //     plan => plan.FieldFixStatus === 'Pending'
            // );

            this.hasPendingStatus = this.actionPlans.some(
                plan => plan.IsCompleted == false
            );

            if (this.hasPendingStatus) {

            }
        }
        console.log(` data, ${JSON.stringify(data)}`);
        console.log(`ap data, ${JSON.stringify(this.actionPlans)}`);
        if (errors) {
            this.hasError = true;
            console.error('GraphQL errors:', errors);
            this.showToast('Error', 'Failed to load action plans', 'error');
        }
    }

    get variables() {
        return { jobCardId: this.recordId };
    }

    statusClick(event) {
        debugger;
        this.selectedStep = event.target.value;
    }

    openModal() {
        debugger;
        this.showModal = true;
    }

    closeModal() {
        debugger;
        this.showModal = false;
    }

    handleStatusChange(event) {
        debugger;
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
            })
            .catch(error => {
                this.showToast('Error', 'Error updating status', 'error');
                console.error(error);
            });

    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}