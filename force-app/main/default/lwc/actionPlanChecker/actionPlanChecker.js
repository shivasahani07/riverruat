import { LightningElement, api, wire } from 'lwc';
import getActionPlansForJobCard from '@salesforce/apex/ActionPlanCheckerController.getActionPlansForJobCard';

export default class ActionPlanChecker extends LightningElement {
    @api recordId;
    actionPlans = [];
    error;

    @wire(getActionPlansForJobCard, { jobCardId: '$recordId' })
    wiredPlans({ data, error }) {
        debugger;
        if (data) {
            this.actionPlans = data.map(plan => ({
                id: plan.Id,
                message: `Action Plan available for this Job Card : ${plan.ActionPlanTemplateVersion?.Name}`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.actionPlans = [];
            console.error('Error fetching action plans:', error);
        }
    }
}