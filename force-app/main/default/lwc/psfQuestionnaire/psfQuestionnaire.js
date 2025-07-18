import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import getQuestionnaires from '@salesforce/apex/PostServiceFeedbackController.getQuestionnaires';
import getRatingPicklistValues from '@salesforce/apex/PostServiceFeedbackController.getRatingPicklistValues';
import saveRatings from '@salesforce/apex/PostServiceFeedbackController.saveRatings';

export default class PsfQuestionnaire extends NavigationMixin(LightningElement) {
    @api recordId;
    @track questionnaires = [];
    @track picklistOptions = [];
    @track error;
    // @track averageRating = null;
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

            const result = await getRatingPicklistValues();
            
            console.log('Picklist Wrapper:', result);

            // Assuming you want to use 'ratingPicklist' for your combobox options
            this.picklistOptions = result.ratingPicklist.map(val => ({ label: val, value: val }));
            this.yesNoPicklistOptions = result.yes_no_ratingPicklist.map(val => ({ label: val, value: val }));
            this.complaintRegardingOptions = result.complaintRegardingValues.map(val => ({ label: val, value: val }));

            const response = await getQuestionnaires({ psfId: this.targetPsfId });
            //this.questionnaires = response.questionnaires || [];

            this.questionnaires = (response.questionnaires || []).map(q => {
                return {
                    ...q,
                    showComplaintType: q.Question__c === 'Complaint, if any?' && q.Rating_Yes_No__c === 'Yes',
                    showAdditionalComments: q.Question__c === 'Complaint, if any?' && q.Rating_Yes_No__c === 'No'
                };
            });

            this.averageRating = response.averageRating;
            this.isSubmitVisible = this.averageRating === -1;

            this.questionnaires.forEach(q => {
                if (q.Rating__c !== undefined) {
                    this.updatedRatings.set(`${q.Id}_Rating__c`, q.Rating__c);
                }
                if (q.Rating_Yes_No__c !== undefined) {
                    this.updatedRatings.set(`${q.Id}_Rating_Yes_No__c`, q.Rating_Yes_No__c);
                }
            });
        } catch (error) {
            console.error('Error loading data:', error);
            this.error = error.body ? error.body.message : error.message;
        }   
    }

    handleComplaintTypeChange(event) {
        const recordId = event.target.dataset.id;
        const selectedValue = event.detail.value;

        this.updatedRatings.set(`${recordId}_Complaint_Regarding__c`, selectedValue);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Complaint_Regarding__c: selectedValue } : q;
        });
    }

    handleIssueText(event) {
        const recordId = event.target.dataset.id;
        const value = event.target.value;

        this.updatedRatings.set(`${recordId}_Complaint_Description__c`, value);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Complaint_Description__c: value } : q;
        });
    }

    handleAdditionalCommentsText(event){
        const recordId = event.target.dataset.id;
        const value = event.target.value;

        this.updatedRatings.set(`${recordId}_Additional_Comments__c`, value);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Additional_Comments__c: value } : q;
        });
    }

    /*
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
            console.error('Error loading data:', error);
            this.error = error.body ? error.body.message : error.message;
        }
    }
    */

    handleRatingChangeForYesNo(event) {
        const recordId = event.target.dataset.id;
        const selectedValue = event.detail.value.toString();

        this.updatedRatings.set(`${recordId}_Rating_Yes_No__c`, selectedValue);

        this.questionnaires = this.questionnaires.map(q => {
            if (q.Id === recordId) {
                return {
                    ...q,
                    Rating_Yes_No__c: selectedValue,
                    showComplaintType: q.Question__c === 'Complaint, if any?' && selectedValue === 'Yes',
                    showAdditionalComments: q.Question__c === 'Complaint, if any?' && selectedValue === 'No'
                };
            }
            return q;
        });
    }



    handleRatingChangeForRating(event) {
        const recordId = event.target.dataset.id;
        const selectedValue = event.detail.value.toString();

        this.updatedRatings.set(`${recordId}_Rating__c`, selectedValue);

        this.questionnaires = this.questionnaires.map(q => {
            return q.Id === recordId ? { ...q, Rating__c: selectedValue } : q;
        });


        this.recalculateAverage();
    }

    recalculateAverage() {
        let total = 0;
        let filledCount = 0;

        for (let q of this.questionnaires) {
            if (
                q.Question__c &&
                q.Question__c.includes('How would you like to rate on the Overall Service experience?')
            ) {
                if (q.Rating__c != null && q.Rating__c !== '') {
                    total += parseFloat(q.Rating__c);
                    filledCount++;
                }
                break; // Only one question needs to be considered
            }
        }

        console.log('filledCount :  ' + filledCount);
        console.log('total : ' + total);
        this.averageRating = filledCount > 0 ? (total / filledCount).toFixed(2) : 0;
        console.log('this.averageRating : ' + this.averageRating);

        this.showComplaintBox = this.averageRating < 7 && filledCount > 0;
    }


    /*
    recalculateAverage() {
        let total = 0;
        let filledCount = 0;
        let numericQuestionCount = 0;

        for (let q of this.questionnaires) {
            if (q.Is_Rating_Question__c) {
                numericQuestionCount++;
                if (q.Rating__c != null && q.Rating__c !== '') {
                    total += parseFloat(q.Rating__c);
                    filledCount++;
                }
            }
        }

        this.averageRating = filledCount > 0 ? (total / filledCount).toFixed(2) : 0;

        this.showComplaintBox = (filledCount === numericQuestionCount) && this.averageRating < 7;
    }
    */

    /*
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
    */


    handleCustomerComplaint(event) {
        this.complaintText = event.target.value;
    }

    submitRatings() {

        // Validate form inputs
        let isValid = true;

        this.template.querySelectorAll('lightning-combobox, lightning-textarea').forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });

        if (!isValid) {
            // Exit early if any field is invalid
            return;
        }
        
        if (this.showComplaintBox && (this.complaintText === '' || this.complaintText === null || this.complaintText === undefined)) {
            alert('Please Describe the Issue Customer is facing.');
            return;
        }

        this.loading = true;
        const updatedList = [];

        this.questionnaires.forEach(q => {
            const record = { Id: q.Id };

            if (this.updatedRatings.has(`${q.Id}_Rating__c`)) {
                record.Rating__c = this.updatedRatings.get(`${q.Id}_Rating__c`);
            }

            if (this.updatedRatings.has(`${q.Id}_Rating_Yes_No__c`)) {
                record.Rating_Yes_No__c = this.updatedRatings.get(`${q.Id}_Rating_Yes_No__c`);
            }

            if (this.updatedRatings.has(`${q.Id}_Complaint_Regarding__c`)) {
                record.Complaint_Regarding__c = this.updatedRatings.get(`${q.Id}_Complaint_Regarding__c`);
            }

            if (this.updatedRatings.has(`${q.Id}_Complaint_Description__c`)) {
                record.Complaint_Description__c = this.updatedRatings.get(`${q.Id}_Complaint_Description__c`);
            }

            if (this.updatedRatings.has(`${q.Id}_Additional_Comments__c`)) {
                record.Additional_Comments__c = this.updatedRatings.get(`${q.Id}_Additional_Comments__c`);
            }

            updatedList.push(record);
        });


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
                        console.log('Navigating to Ticket:', ticketId);

                        getRecordNotifyChange([{ recordId: ticketId }]);

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: ticketId,
                                objectApiName: 'Ticket__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        console.log('No Ticket created, navigating to PSF:', this.targetPsfId);

                        getRecordNotifyChange([{ recordId: this.targetPsfId }]);

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
                console.error('Error saving data:', error);
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

    /*
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
                        console.log('Navigating to Ticket:', ticketId);

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
                        console.log('No Ticket created, navigating to PSF:', this.targetPsfId);

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
                console.error('Error saving data:', error);
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
            console.error(' Error loading data:', error);
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
                        //  Navigate to Ticket__c record
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: ticketId,
                                objectApiName: 'Ticket__c',
                                actionName: 'view'
                            }
                        });
                    } else {
                        //  Refresh view first
                        eval("$A.get('e.force:refreshView').fire();");

                        //  After refresh, navigate to Post_Service_Feedback__c record
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
                console.error(' Error saving data:', error);
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