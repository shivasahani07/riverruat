import { LightningElement, api, wire } from 'lwc';
import getTaskDetails from '@salesforce/apex/TaskController.getTaskDetails';

import { CloseActionScreenEvent } from 'lightning/actions';


const FIELDS = ['Task.Subject', 'Task.Status', 'Task.ActivityDate'];

export default class TaskDetails extends LightningElement {
    @api recordId;
    task;
    error;

    @wire(getTaskDetails, { taskId: '$recordId' })
    wiredTask({ error, data }) {
        if (data) {
            console.log('✅ Task data:', data);
            this.task = data;
            this.error = undefined;
        } else if (error) {
            console.error('❌ Error loading task:', error);
            this.error = error;
            this.task = undefined;
        }
    }

     handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}