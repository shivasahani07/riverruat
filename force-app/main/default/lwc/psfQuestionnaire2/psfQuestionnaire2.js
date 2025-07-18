import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import getQuestionnaires from '@salesforce/apex/PostServiceFeedbackController.getQuestionnaires';
import getRatingPicklistValues from '@salesforce/apex/PostServiceFeedbackController.getRatingPicklistValues';
import saveRatings from '@salesforce/apex/PostServiceFeedbackController.saveRatings';

export default class PsfQuestionnaire2 extends NavigationMixin(LightningElement) {
    @api recordId;
    @track questionnaires = [];
    @track picklistOptions = [];
    @track error;
    @track averageRating = null;
    @track isSubmitVisible = false;
    // ----------------- CALLING THIS COMPONENT FROM TASK ------------------------------- // 
    @api psfId;
    @api taskId;
    loading = false;
    
    @track averageRating = 0;
    @track showComplaintBox = false;
    @track complaintText = '';

    // LOGIC TO HANDLE FROM PSF RECORD PAGE AS WELL AS FROM TASK
    connectedCallback() {
        if (!this.psfId) {
            console.error('psfId is missing in LWC!');
            return;
        }
        console.log('LWC received psfId:', this.psfId);
        console.log('recordId in connectedCallback : ', this.taskId);
        this.initComponent();
    }

    get targetPsfId() {
        return this.psfId || this.recordId;
    } 

    get isPsfPage() {
        return this.recordId && !this.psfId;
    }

    updatedRatings = new Map();

    async initComponent() {
        try {
            console.log('taskId : ', this.taskId);

            const options = await getRatingPicklistValues();
            this.picklistOptions = options.map(val => ({ label: val, value: val }));

            const response = await getQuestionnaires({ psfId: this.targetPsfId });
            //const response = await getQuestionnaires({ psfId: this.recordId });
            this.questionnaires = response.questionnaires || [];
            this.averageRating = response.averageRating;
            this.isSubmitVisible = this.averageRating === -1;

            this.questionnaires.forEach(q => {
                this.updatedRatings.set(q.Id, q.Rating__c);
            });
        } catch (error) {
            console.error('❌ Error loading data:', error);
            this.error = error.body ? error.body.message : error.message;
        }
    }

    handleRatingChange(event) {
        const recordId = event.target.dataset.id;
        const selectedValue =  event.detail.value.toString();
        this.updatedRatings.set(recordId, selectedValue);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Rating__c: selectedValue } : q;
        });

        
         // Easy average calculation
        let total = 0;
        let filledCount = 0;

        for (let q of this.questionnaires) {
            if (q.Rating__c != null && q.Rating__c !== '') {
                total += Number(q.Rating__c);
                filledCount++;
            }
        }

        this.averageRating = filledCount > 0 ? total / filledCount : 0;

        // Only show box if ALL ratings are filled AND average is below 7
        this.showComplaintBox = filledCount === this.questionnaires.length && this.averageRating < 7;
    }

    handleCustomerComplaint(event) {
        this.complaintText = event.target.value;
    }

    submitRatings() {

        if(this.showComplaintBox && (this.complaintText === '' || this.complaintText === null || this.complaintText === undefined)){
            alert('Please Describe the Issue Customer is facing.');
            return;
        }

        this.loading = true; 
        const updatedList = [];

        for (let [id, rating] of this.updatedRatings.entries()) {
            updatedList.push({ Id: id, Rating__c: rating });
        }

        saveRatings({ updatedQuestions: updatedList, psfId: this.targetPsfId, taskId: this.taskId, complaintText: this.complaintText })
            .then((ticketId) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Questionnaire updated successfully',
                        variant: 'success'
                    })
                );

                setTimeout(() => {
                    if (ticketId) {
                        console.log('✅ Navigating to Ticket:', ticketId);

                        getRecordNotifyChange([{recordId: ticketId}]);

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: ticketId,
                                objectApiName: 'Ticket__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        console.log('ℹ️ No Ticket created, navigating to PSF:', this.targetPsfId);

                        // Before navigation to PSF
                        getRecordNotifyChange([{recordId: this.targetPsfId}]);

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.targetPsfId,
                                objectApiName: 'Post_Service_Feedback__c',
                                actionName: 'view'
                            }
                        });
                    }
                }, 100);
            })
            .catch(error => {
                console.error('❌ Error saving data:', error);
                this.error = error.body ? error.body.message : error.message;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.error,
                        variant: 'error'
                    })
                );
            });
    }

}

/* // LOGIC TO HANDLE ONLY FROM PSF RECORD PAGE 
    updatedRatings = new Map();

    connectedCallback() {
        this.initComponent();
    }

    async initComponent() {
        try {
            const options = await getRatingPicklistValues();
            this.picklistOptions = options.map(val => ({ label: val, value: val }));

            const response = await getQuestionnaires({ psfId: this.recordId });
            this.questionnaires = response.questionnaires || [];
            this.averageRating = response.averageRating;
            this.isSubmitVisible = this.averageRating === -1;

            this.questionnaires.forEach(q => {
                this.updatedRatings.set(q.Id, q.Rating__c);
            });
        } catch (error) {
            console.error('❌ Error loading data:', error);
            this.error = error.body ? error.body.message : error.message;
        }
    }

    handleRatingChange(event) {
        const recordId = event.target.dataset.id;
        const selectedValue = event.detail.value;
        this.updatedRatings.set(recordId, selectedValue);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Rating__c: selectedValue } : q;
        });
    }

    submitRatings() {
        const updatedList = [];

        for (let [id, rating] of this.updatedRatings.entries()) {
            updatedList.push({ Id: id, Rating__c: rating });
        }

        saveRatings({ updatedQuestions: updatedList, psfId: this.recordId })
            .then((ticketId) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Questionnaire is updated successfully',
                        variant: 'success'
                    })
                );

                setTimeout(() => {
                    if (ticketId) {
                        // ✅ Navigate to Ticket__c record
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: ticketId,
                                objectApiName: 'Ticket__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        // ✅ Refresh view first
                        eval("$A.get('e.force:refreshView').fire();");

                        // ✅ After refresh, navigate to Post_Service_Feedback__c record
                        setTimeout(() => {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: this.recordId,
                                    objectApiName: 'Post_Service_Feedback__c',
                                    actionName: 'view'
                                }
                            });
                        }, 500);
                    }
                }, 300);
            })
            .catch(error => {
                console.error('❌ Error saving data:', error);
                this.error = error.body ? error.body.message : error.message;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.error,
                        variant: 'error'
                    })
                );
            });
    }
    */