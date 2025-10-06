import { LightningElement, track,wire } from 'lwc';
import ConvertLeadAndShowTheOpportunity from '@salesforce/apex/OpportunityTriggerHandler.ConvertLeadAndShowTheOpportunity';
import createOpportunity from '@salesforce/apex/OpportunityTriggerHandler.createOpportunity';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import Opportunity_OBJECT from '@salesforce/schema/Opportunity';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import EnqPrimSource_FIELD from '@salesforce/schema/Opportunity.Enquiry_Primary_Source__c';
import EnqSecSource_FIELD from '@salesforce/schema/Opportunity.Secondary_Sources__c';
export default class CreateOpportunity extends NavigationMixin(LightningElement) {

    @track phoneValue;
    createEnquiry = false;
    convertLead = false;
    radioButtons = true;

    createNewBooking = false;
    createNewEnquiry = false;
    createNewEnquiryAndTestDrive = false;
    groupButtonName = '';
    recordId;
    ifExistingOppIsThereButNotClosedWon = false;
    createNewOpp = false;
    createNewTestDriveRecord = false;
    ifExistingOppIsThereButNotClosedWonAndCreateNewOppLineItems = false;
    createNewOppLineItem = false;
    
    FirstName;
    oppoObj = {
        fName: '',
        lName: '',
        phone: '',
        pincode: '',
        primSorceValue:'',
        secSourceValue:''
    }

    @track primarySourceOptions;
    @track secondarySourceOptions;

    @track primSorceValue;
    @track secSourceValue;

    secondarySourceData;

    @wire(getObjectInfo, { objectApiName: Opportunity_OBJECT })
    OppInfo;

    @wire(getPicklistValues, { recordTypeId: '$OppInfo.data.defaultRecordTypeId', fieldApiName: EnqPrimSource_FIELD })
    CountryFieldInfo({ data, error }) {
        if (data) this.primarySourceOptions = data.values;
    }

    @wire(getPicklistValues, { recordTypeId: '$OppInfo.data.defaultRecordTypeId', fieldApiName: EnqSecSource_FIELD })
    StateFieldInfo({ data, error }) {
        if (data) {
            this.secondarySourceData = data;
        }
    }

    handlePrimarySourceChange(event) {
        const selectedValue = event.detail.value;
        this.oppoObj.primSorceValue = selectedValue;
        const controllerKey = this.secondarySourceData.controllerValues[selectedValue];

        this.secondarySourceOptions = this.secondarySourceData.values.filter(
            (option) => option.validFor.includes(controllerKey)
        );
    }

    handleSecondarySourceChange(event) {
        this.oppoObj.secSourceValue = event.detail.value;
        //this.secSourceValue = event.detail.value;
    }

    handleChange(event) {
        debugger;
        const inpName = event.target.name;
        if (inpName === 'phone') {
            this.phoneValue = event.target.value;
        }
        if (inpName === 'fName') {
            this.oppoObj.fName = event.target.value;
            this.FirstName = event.target.value;
            this.FirstName += ' - Test Drive';
        }
        if (inpName === 'lName') {
            this.oppoObj.lName = event.target.value;
        }
        if (inpName === 'Newphone') {
            this.oppoObj.phone = event.target.value;
        }
        if (inpName === 'pincode') {
            this.oppoObj.pincode = event.target.value;
        }
    }

    handleBack() {
        this.convertLead = false;
        this.radioButtons = true;
    }

    handleButtonClick(event) {
        debugger;
        this.groupButtonName = event.target.name;

        this.convertLead = true;
        this.radioButtons = false;
    }

    handleClick() {
        debugger;
        if (this.phoneValue && this.phoneValue.length !== 10) {
            alert('Please enter a valid 10-digit phone number.');
            return;
        }

        if (this.groupButtonName === 'CreateBooking') {
            this.checkOpportuntiy();
        } else if (this.groupButtonName === 'CreateEnquiry') {
            this.checkOpportuntiy();
        } else if (this.groupButtonName === 'CreateEnquiryAndTestDrive') {
            this.checkOpportuntiy();
        }
    }

    checkOpportuntiy() {
        debugger;
        if (this.groupButtonName === 'CreateBooking') {
            ConvertLeadAndShowTheOpportunity({ phoneNumber: this.phoneValue })
                .then(result => {
                    if (result === 'No Lead found') {
                        this.createNewEnquiry = true;
                        this.createNewOpp = true;
                        this.convertLead = false;
                        this.radioButtons = false;
                    } else if (result.includes('Lead converted successfully. Opportunity created: ') || result.includes('Opportunity already exists for this phone number: ')) {
                        const match = result.match(/[a-zA-Z0-9]{18}/);
                        if (match) {
                            const recordId = match[0];
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: recordId,
                                    objectApiName: 'Opportunity',
                                    actionName: 'view'
                                }
                            });
                            if (result.includes('Opportunity already exists for this phone number: ')) {
                                setTimeout(() => {
                                    this.showToast('Success', 'Enquiry Transfered successfully.', 'success');
                                    this.createEnquiry = false;
                                }, 1000);
                            } else {
                                setTimeout(() => {
                                    this.showToast('Success', 'Enquiry created successfully', 'success');
                                    this.createEnquiry = false;
                                }, 1000);
                            }

                        } else {
                            console.log('No ID found.');
                        }
                    }
                }).catch(error => {
                    console.error('Error creating opportunity or converting lead:', error);
                    alert('An error occurred while processing your request. Please try again later.');
                });
        } else if (this.groupButtonName === 'CreateEnquiry') {
            ConvertLeadAndShowTheOpportunity({ phoneNumber: this.phoneValue })
                .then(result => {
                    if (result === 'No Lead found') {
                        this.createNewEnquiry = true;
                        this.createNewOpp = true;
                        this.convertLead = false;
                        this.radioButtons = false;
                    } else if (result.includes('Lead converted successfully. Opportunity created: ') || result.includes('Opportunity already exists for this phone number: ')) {
                        const match = result.match(/[a-zA-Z0-9]{18}/);
                        if (match) {
                            const recordId = match[0];
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: recordId,
                                    objectApiName: 'Opportunity',
                                    actionName: 'view'
                                }
                            });
                            if (result.includes('Opportunity already exists for this phone number: ')) {
                                setTimeout(() => {
                                    this.showToast('Success', 'Enquiry Transfered successfully.', 'success');
                                    this.createEnquiry = false;
                                }, 1000);
                            } else {
                                setTimeout(() => {
                                    this.showToast('Success', 'Enquiry created successfully', 'success');
                                    this.createEnquiry = false;
                                }, 1000);
                            }

                        } else {
                            console.log('No ID found.');
                        }
                    }
                }).catch(error => {
                    console.error('Error creating opportunity or converting lead:', error);
                    alert('An error occurred while processing your request. Please try again later.');
                });
        } else if (this.groupButtonName === 'CreateEnquiryAndTestDrive') {
            ConvertLeadAndShowTheOpportunity({ phoneNumber: this.phoneValue })
                .then(result => {
                    if (result === 'No Lead found') {
                        this.createNewEnquiryAndTestDrive = true;
                        this.createNewOpp = true;
                        this.convertLead = false;
                        this.radioButtons = false;
                    } else if (result.includes('Lead converted successfully. Opportunity created: ') || result.includes('Opportunity already exists for this phone number: ')) {
                        const match = result.match(/[a-zA-Z0-9]{18}/);
                        if (match) {
                            const recordId = match[0];
                            this.recordId = recordId;
                            this.createNewEnquiryAndTestDrive = true;
                            this.convertLead = false;
                            this.ifExistingOppIsThereButNotClosedWon = true;
                        } else {
                            console.log('No ID found.');
                        }
                    }
                }).catch(error => {
                    console.error('Error creating opportunity or converting lead:', error);
                    alert('An error occurred while processing your request. Please try again later.');
                });
        }
    }

    handleCancel() {
        debugger;
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'home'
            }
        });
    }

    handleSuccess() {
        debugger;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
        this.showToast('Success', 'Enquiry Created successfully And Under that Test Drive is also Created', 'success');
    }

    handleLineSuccess(){
        debugger;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
        this.showToast('Success', 'Enquiry Created successfully And Under that Test Drive is also Created', 'success');
    }

    handleOppLineSave(){
        debugger;
        if (this.oppoObj.fName == null || this.oppoObj.fName == undefined || this.oppoObj.fName.trim() === '') {
            alert('Please enter First Name');
            return;
        }
        if (this.oppoObj.lName == null || this.oppoObj.lName == undefined || this.oppoObj.lName.trim() === '') {
            alert('Please enter Last Name');
            return;
        }
        if (this.oppoObj.phone == null || this.oppoObj.phone == undefined || this.oppoObj.phone.trim() === '') {
            this.oppoObj.phone = this.phoneValue;
        }
        if (this.oppoObj.pincode == null || this.oppoObj.pincode == undefined || this.oppoObj.pincode.trim() === '') {
            alert('Please enter pincode');
            return;
        }
        if (this.oppoObj.primSorceValue == null || this.oppoObj.primSorceValue == undefined || this.oppoObj.primSorceValue.trim() === '') {
            alert('Please enter Primary Source');
            return;
        }
        if (this.oppoObj.secSourceValue == null || this.oppoObj.secSourceValue == undefined || this.oppoObj.secSourceValue.trim() === '') {
            alert('Please enter Secondary Source');
            return;
        }

        createOpportunity({ objName: this.oppoObj })
            .then(result => {
                if (result.includes('Opportunity created with Id: ')) {
                    const match = result.match(/[a-zA-Z0-9]{18}/);
                    if (match) {
                        const recordId = match[0];
                        this.recordId = recordId;
                        this.createNewBooking = false;
                        this.createNewOppLineItem = true;
                    }
                }
            }).catch(error => {
                console.error('Error creating opportunity or converting lead:', error);
                alert('An error occurred while processing your request. Please try again later.');
            });
    }

    handleOppSave() {
        debugger;
        if (this.oppoObj.fName == null || this.oppoObj.fName == undefined || this.oppoObj.fName.trim() === '') {
            alert('Please enter First Name');
            return;
        }
        if (this.oppoObj.lName == null || this.oppoObj.lName == undefined || this.oppoObj.lName.trim() === '') {
            alert('Please enter Last Name');
            return;
        }
        if (this.oppoObj.phone == null || this.oppoObj.phone == undefined || this.oppoObj.phone.trim() === '') {
            this.oppoObj.phone = this.phoneValue;
        }
        if (this.oppoObj.pincode == null || this.oppoObj.pincode == undefined || this.oppoObj.pincode.trim() === '') {
            alert('Please enter pincode');
            return;
        }
        if (this.oppoObj.primSorceValue == null || this.oppoObj.primSorceValue == undefined || this.oppoObj.primSorceValue.trim() === '') {
            alert('Please enter Primary Source');
            return;
        }
        if (this.oppoObj.secSourceValue == null || this.oppoObj.secSourceValue == undefined || this.oppoObj.secSourceValue.trim() === '') {
            alert('Please enter Secondary Source');
            return;
        }

        createOpportunity({ objName: this.oppoObj })
            .then(result => {
                if (result.includes('Opportunity created with Id: ')) {
                    const match = result.match(/[a-zA-Z0-9]{18}/);
                    if (match) {
                        const recordId = match[0];
                        this.recordId = recordId;
                        this.createNewEnquiryAndTestDrive = false;
                        this.createNewTestDriveRecord = true;
                    }
                }
            }).catch(error => {
                console.error('Error creating opportunity or converting lead:', error);
                alert('An error occurred while processing your request. Please try again later.');
            });
    }

    handleSave() {
        debugger;
        if (this.oppoObj.fName == null || this.oppoObj.fName == undefined || this.oppoObj.fName.trim() === '') {
            alert('Please enter First Name');
            return;
        }
        if (this.oppoObj.lName == null || this.oppoObj.lName == undefined || this.oppoObj.lName.trim() === '') {
            alert('Please enter Last Name');
            return;
        }
        if (this.oppoObj.phone == null || this.oppoObj.phone == undefined || this.oppoObj.phone.trim() === '') {
            this.oppoObj.phone = this.phoneValue;
        }
        if (this.oppoObj.pincode == null || this.oppoObj.pincode == undefined || this.oppoObj.pincode.trim() === '') {
            alert('Please enter pincode');
            return;
        }
        if (this.oppoObj.primSorceValue == null || this.oppoObj.primSorceValue == undefined || this.oppoObj.primSorceValue.trim() === '') {
            alert('Please enter Primary Source');
            return;
        }
        if (this.oppoObj.secSourceValue == null || this.oppoObj.secSourceValue == undefined || this.oppoObj.secSourceValue.trim() === '') {
            alert('Please enter Secondary Source');
            return;
        }

        createOpportunity({ objName: this.oppoObj })
            .then(result => {
                if (result.includes('Opportunity created with Id: ')) {
                    const match = result.match(/[a-zA-Z0-9]{18}/);
                    if (match) {
                        const recordId = match[0];
                        this.recordId = recordId;

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: recordId,
                                objectApiName: 'Opportunity',
                                actionName: 'view'
                            }
                        });
                        setTimeout(() => {
                            this.showToast('Success', 'Enquiry created successfully.', 'success');
                            this.createEnquiry = false;
                        }, 1000);
                    } else {
                        console.log('No ID found.');
                    }

                }
            }).catch(error => {
                console.error('Error creating opportunity or converting lead:', error);
                alert('An error occurred while processing your request. Please try again later.');
            });
    }

    showToast(title, message, variant) {
        debugger;
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

}