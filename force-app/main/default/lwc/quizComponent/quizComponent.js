import { LightningElement, track, api, wire } from 'lwc';
import getQuizData from '@salesforce/apex/QuizController.getQuizData';
import createOrUpdateQuizTemplates from '@salesforce/apex/QuizController.createOrUpdateQuizTemplates';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class QuizComponent extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showWelcomePage = true;
    @track showSection = false;
    @track showSpinner = false;
    @track showSubmitSpinner = false;
    @track currentSectionIndex = 0;
    @track sections = [];
    scores = {};
    remarks = {};

    connectedCallback() {
        console.log('Connected Callback - Fetching quiz data...');
        this.fetchQuizData();
    }

    fetchQuizData() {
        debugger;
        getQuizData({ templateName: 'ARM Checklist' })
            .then(result => {
                console.log('Quiz data fetched successfully:', result);
                this.sections = Object.keys(result).map(sectionName => {
                    return {
                        title: sectionName,
                        questions: result[sectionName].map(q => q.question)
                    };
                });
            })
            .catch(error => {
                console.error('Error loading quiz data:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading quiz data',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    get currentSection() {
        return this.sections[this.currentSectionIndex];
    }

    get isLastSection() {
        return this.currentSectionIndex === this.sections.length - 1;
    }

    get isFirstSection() {
        return this.currentSectionIndex === 0;
    }

    handleStart() {
        this.showSpinner = true;
        console.log('Starting quiz...');
        setTimeout(() => {
            this.showSpinner = false;
            this.showWelcomePage = false;
            this.showSection = true;
            this.updateFields();
        }, 2000);
    }

    handleScoreChange(event) {
        debugger;
        const question = event.target.name;
        const score = event.target.value;
        console.log(`Score changed: ${question} -> ${score}`);
        this.scores[question] = score;

        const parent = event.target.closest('.question-container');
        parent.querySelectorAll('.score-box').forEach(box => {
            box.classList.remove('selected');
        });
        event.target.closest('.score-box').classList.add('selected');

        parent.querySelectorAll('.score-text').forEach(text => {
            text.classList.remove('selected-text');
        });
        if (score === '1') {
            parent.querySelector('.score-text-satisfied').classList.add('selected-text');
        } else if (score === '0.5') {
            parent.querySelector('.score-text-improve').classList.add('selected-text');
        } else if (score === '0') {
            parent.querySelector('.score-text-unsatisfied').classList.add('selected-text');
        }
    }

    handleRemarkChange(event) {
        const question = event.target.dataset.question;
        const remarks = event.target.value;
        console.log(`Remark changed: ${question} -> ${remarks}`);
        this.remarks[question] = remarks;
    }

    handleNext() {
        if (this.currentSectionIndex < this.sections.length - 1) {
            console.log('Navigating to next section...');
            this.currentSectionIndex++;
            this.showSectionWithAnimation();
        }
    }

    handlePrevious() {
        if (this.currentSectionIndex > 0) {
            console.log('Navigating to previous section...');
            this.currentSectionIndex--;
            this.showSectionWithAnimation();
        }
    }

    handleCancel() {
        console.log('Cancelling quiz and redirecting...');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    showSectionWithAnimation() {
        const sectionCard = this.template.querySelector('.section-card');
        sectionCard.classList.remove('animate-slide-in');
        void sectionCard.offsetWidth; // trigger reflow
        sectionCard.classList.add('animate-slide-in');
        this.updateFields();
    }

    updateFields() {
        console.log('Updating fields with saved scores and remarks...');
        this.template.querySelectorAll('.question-container').forEach(container => {
            const question = container.querySelector('input[type="radio"]').name;
            const score = this.scores[question];
            if (score !== undefined) {
                container.querySelectorAll('input[type="radio"]').forEach(radio => {
                    radio.checked = radio.value === score;
                    if (radio.checked) {
                        radio.closest('.score-box').classList.add('selected');
                    } else {
                        radio.closest('.score-box').classList.remove('selected');
                    }
                });

                container.querySelectorAll('.score-text').forEach(text => {
                    text.classList.remove('selected-text');
                });
                if (score === '1') {
                    container.querySelector('.score-text-satisfied').classList.add('selected-text');
                } else if (score === '0.5') {
                    container.querySelector('.score-text-improve').classList.add('selected-text');
                } else if (score === '0') {
                    container.querySelector('.score-text-unsatisfied').classList.add('selected-text');
                }
            }

            const remark = this.remarks[question];
            if (remark !== undefined) {
                container.querySelector('lightning-input').value = remark;
            }
        });
    }

    handleSubmit() {
        debugger;
        this.showSection = false;
        this.showSubmitSpinner = true;
        console.log('Submitting quiz...');

        const questionAnswers = this.sections.flatMap(section =>
            section.questions.map(question => ({
                question,
                score: this.scores[question] || '0',
                remarks: this.remarks[question] || ''
            })).filter(qa => this.scores.hasOwnProperty(qa.question))
        );

        createOrUpdateQuizTemplates({ accountId: this.recordId, questionAnswers })
            .then(() => {
                console.log('Quiz submitted successfully.');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Quiz records created/updated and account status updated',
                        variant: 'success'
                    })
                );
                this.showSection = false;
                this.showWelcomePage = true;
                this.showSubmitSpinner = false;

                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Account',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                console.error('Error submitting quiz:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.showSubmitSpinner = false;
                this.showSection = true;
            });
    }
}