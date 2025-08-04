import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import WORKORDER_ID_FIELD from '@salesforce/schema/WorkOrder.Id';
import STATUS_FIELD from '@salesforce/schema/WorkOrder.Status';

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
            }
          }
        }
      }
    }
  }
`;

export default class JobCardActionPlanApproval extends LightningElement {
  @api recordId;  // Populated by the Quick Action
  actionPlans = [];
  hasPendingStatus = false;
  isLoading = true;
  hasError = false;
  statusValue = 'Submit For Approval'; // Target status 
  
  connectedCallback() {
    console.log('record id',JSON.stringify(this.recordId))
  }

  @wire(graphql, {
    query: ACTION_PLAN_WITH_STATUS,
    variables: "$variables"
  })
  wiredActionPlans({ data, errors }) {
    this.isLoading = false;

    if (data) {
      this.actionPlans = data.uiapi.query.ActionPlan?.edges.map(edge => ({
        Id: edge.node.Id,
        FieldFixStatus: edge.node.Field_Fix__r?.Status__c?.value
      })) || [];

      this.hasPendingStatus = this.actionPlans.some(
        plan => plan.FieldFixStatus === 'Pending'
      );
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

  handleSubmit() {
    this.isLoading = true;
    this.updateStatus();
  }

  updateStatus() {
    const fields = {};
    fields[WORKORDER_ID_FIELD.fieldApiName] = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = this.statusValue;

    updateRecord({ fields })
      .then(() => {
        this.showToast('Success', 'Submitted for approval', 'success');
        this.dispatchEvent(new CloseActionScreenEvent());
        this.isLoading = false;
      })
      .catch(error => {
        this.isLoading = false;
        // this.showToast('Error', error.body.message, 'error');
        this.showToast('Error', `${JSON.stringify(error.body.output.fieldErrors)}`, 'error');
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}