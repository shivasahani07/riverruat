import { LightningElement,track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitDailyStoreOperations from '@salesforce/apex/dailyStoreOperations.submitDailyStoreOperations';
export default class DailyStoreOperationsForm extends LightningElement {

    @track showForm = false;
    @track showModal = true;
    @track firstSlide = true;
    @track secondSlide = false;
    @track thirdSlide = false;
    @track fourthSlide = false;
    @track fifthSlide = false;
    @track sixthSlide = false;
    @track currentStep = 1;
    @track  step2Variant = '2';
    @track  step3Variant = '3';
    @track  step4Variant = '4';
    @track  step5Variant = '5';
    @track  step6Variant = '6';
    


    @track formData = {};
    // Define the options for Yes and No
    yesNoOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    // Define the options for Stock Level
    stockLevelOptions = [
        { label: 'Low', value: 'low' },
        { label: 'Sufficient', value: 'sufficient' },
        { label: 'Excess', value: 'excess' }
    ];

    // Define the options for Overall Customer Satisfaction
    satisfactionOptions = [
        { label: 'Excellent', value: 'excellent' },
        { label: 'Good', value: 'good' },
        { label: 'Average', value: 'average' },
        { label: 'Poor', value: 'poor' }
    ];

    // Define the options for Cleanliness Level
    cleanlinessOptions = [
        { label: 'Excellent', value: 'excellent' },
        { label: 'Good', value: 'good' },
        { label: 'Fair', value: 'fair' },
        { label: 'Poor', value: 'poor' }
    ];

    // Define the options for Staff Attendance
    attendanceOptions = [
        { label: 'Complete', value: 'complete' },
        { label: 'Partial', value: 'partial' },
        { label: 'Incomplete', value: 'incomplete' }
    ];


    openModal(){
        debugger;
        this.showModal = true;
        this.firstSlide = true;
        this.currentStep = 1;
    }

    handleChange(event) {
        debugger;
        const { name, value } = event.target;
        this.formData = { ...this.formData, [name]: value };
    }

    handlenext(){
        debugger;
        console.log('this.currentStep===>'+this.currentStep);
        this.currentStep = parseInt(this.currentStep);
        if(this.currentStep < 6){
            this.currentStep += 1;  
        }
        if(this.currentStep === 2){
            this.currentStep = JSON.stringify(this.currentStep);
            this.firstSlide = false;
            this.secondSlide = true;
        } else if(this.currentStep === 3){
            this.currentStep = JSON.stringify(this.currentStep);
            this.secondSlide = false;
            this.thirdSlide = true;
        } else if(this.currentStep === 4){
            this.currentStep = JSON.stringify(this.currentStep);
            this.thirdSlide = false;
            this.fourthSlide = true;
        } else if(this.currentStep === 5){
            this.currentStep = JSON.stringify(this.currentStep);
            this.fourthSlide = false;
            this.fifthSlide = true;
        } else if(this.currentStep === 6){
            this.currentStep = JSON.stringify(this.currentStep);
            this.fifthSlide = false;
            this.sixthSlide = true;
        }
    }
    
     handleSelected(event) {
         debugger;
        // Capture the value of the selected radio button
        const selectedValue = event.target.value;
        
        // Store the value in the formData object
        this.formData.issuesNoted = selectedValue;

        // For debugging purposes
        console.log('Selected Value:', selectedValue);
        console.log('Form Data:', this.formData);
    }

    handleStockLevelChange(event) {
        debugger;
        // Capture the value of the selected radio button
        const selectedValue = event.target.value;

        // Store the value in the formData object
        this.formData.stockLevel = selectedValue;

        // For debugging purposes
        console.log('Selected Stock Level:', selectedValue);
        console.log('Form Data:', this.formData);
    }

     handleShortageChange(event) {
        // Capture the value of the selected radio button
        debugger;
        const selectedValue = event.target.value;

        // Store the value in the formData object
        this.formData.shortage = selectedValue;

        // For debugging purposes
        console.log('Selected Shortage:', selectedValue);
        console.log('Form Data:', this.formData);
    }


    handleBack(){
        debugger;
        this.currentstep = parseInt(this.currentStep);
        if(this.currentStep <=6){
            this.currentStep -= 1;  
        }if(this.currentStep === 5){
            this.currentStep=JSON.stringify(this.currentStep);
            //this.step2Variant = 'success';
            this.sixthSlide = false;
            this.fifthSlide = true;

        }else if(this.currentStep === 4){
           this.currentStep=JSON.stringify(this.currentStep);
            //this.step3Variant = 'success';
            this.fifthSlide = false;
            this.fourthSlide = true;
        }else if(this.currentStep === 3){
            this.currentStep=JSON.stringify(this.currentStep);
           // this.step2Variant = 'success';
            this.fourthSlide = false;
            this.thirdSlide = true;
        }else if(this.currentStep === 2){
           this.currentStep=JSON.stringify(this.currentStep);
           // this.step2Variant = 'success';
            this.thirdSlide = false;
            this.secondSlide = true;
        }else if(this.currentStep === 1){
            this.currentStep=JSON.stringify(this.currentStep);
            //this.step2Variant = 'success';
            this.secondSlide = false;
            this.firstSlide = true;
        }


    }

    handleSubmit() {
        debugger;
        console.log('this.formData==>'+this.formData);
        submitDailyStoreOperations({ formData: JSON.stringify(this.formData) })
            .then(result => {
                
                console.log('Record saved:', result);
                this.showNotification('Success','Record Saved Successfully..','success');
                this.formData = {};
                
                this.showModal = false;
                this.sixthSlide = false;
                this.firstSlide = false;
                
            })
            .catch(error => {
                
                console.error('Error saving record:', error);
            });
    }

     closeModal() {
         debugger;
        this.showModal = false;
        

    }


    showNotification(title,message,variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }


}