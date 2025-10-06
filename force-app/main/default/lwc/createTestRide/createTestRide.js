import { LightningElement, track, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createEvent from '@salesforce/apex/OpportunityTriggerHandler.createEvent';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import testDrive from '@salesforce/schema/Test_Drive__c';
import Ride_Type from '@salesforce/schema/Test_Drive__c.Ride_Type__c';
import RATING_FIELD from '@salesforce/schema/Test_Drive__c.Test_Drive_Status__c';

export default class CreateTestRide extends LightningElement {

    @track dateObj = {};
    @api recordId;
    showSpinner = true;
    threshold = false;

    minDateTime;
    @track optionsCategory = [];
    @track RideOptions = [];
    showAddress = false;

    @wire(getObjectInfo, { objectApiName: testDrive })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: RATING_FIELD })
    wiredStatusData({ error, data }) {
        debugger;
        if (data) {
            this.optionsCategory = data.values;
        } else if (error) {
            console.error('Error in Industry picklist field', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Ride_Type })
    wiredTypeData({ error, data }) {
        debugger;
        if (data) {
            this.RideOptions = data.values;
        } else if (error) {
            console.error('Error in Industry picklist field', JSON.stringify(error));
        }
    }

    connectedCallback() {
        debugger;
        const url = window.location.href.toString();
        const queryParams = url.split("&");

        const recordIdParam = queryParams.find(param => param.includes("recordId"));

        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");

            if (recordIdKeyValue.length === 2) {
                this.recordId = recordIdKeyValue[1];
            } else {
                console.error("Invalid recordId parameter format");
            }
        } else {
            console.error("recordId parameter not found in the URL");
        }
        const now = new Date();
        const localIsoString = new Date(now.getTime() - now.getTimezoneOffset() * 60000)
            .toISOString()
            .slice(0, 16);

        this.minDateTime = localIsoString;
        this.showSpinner = false;

    }

    handleChange(event) {
        debugger;
        const { name, value, type } = event.target;

        let updatedValue = value;

        if (type === 'datetime-local') {
            let date = new Date(value);
            let istOffsetInMs = 5.5 * 60 * 60 * 1000;
            let istTime = new Date(date.getTime() + istOffsetInMs);
            updatedValue = istTime.toISOString();
        }

        if (event.target.localName === 'lightning-input-address') {
            const address = event.detail;

            this.dateObj = {
                ...this.dateObj,
                street: address.street,
                city: address.city,
                country: address.country,
                postalCode: address.postalCode
            };

            console.log('Updated dateObj with address =>', JSON.stringify(this.dateObj));
            return;
        }

        if (name === 'rideType' && value === 'HTR') {
            this.showAddress = true;
        }

        if (name === 'rideType' && value === 'STR') {
            this.showAddress = false;
        }

        this.dateObj = {
            ...this.dateObj,
            [name]: updatedValue,
            recordId: this.recordId
        };

        console.log('Updated dateObj ======>', JSON.stringify(this.dateObj));
    }


    handleSave() {
        debugger;
        let isValid = true;
        this.showSpinner = true;

        const startDate = this.template.querySelector('.startDate');
        const Status = this.template.querySelector('.Status');
        const rideType = this.template.querySelector('.rideType');

        if (!startDate || !startDate.value) {
            startDate.setCustomValidity('Please provide the Start Date');
            isValid = false;
        } else {
            const selectedDateTime = new Date(startDate.value);
            const now = new Date();

            if (selectedDateTime < now) {
                startDate.setCustomValidity('Start Date cannot be in the past');
                isValid = false;
            } else {
                startDate.setCustomValidity('');
            }
        }

        if (startDate) {
            startDate.reportValidity();
        }


        if (Status && !Status.value) {
            Status.setCustomValidity('Please provide the Status value.');
            isValid = false;
        } else {
            Status.setCustomValidity('');
        }
        Status && Status.reportValidity();

        if (rideType && !rideType.value) {
            rideType.setCustomValidity('Please provide the Ride Type value.');
            isValid = false;
        } else {
            rideType.setCustomValidity('');
        }
        rideType && rideType.reportValidity();

        if (rideType?.value === 'HTR') {
            if (!this.dateObj || !this.dateObj.street || !this.dateObj.city || !this.dateObj.country || !this.dateObj.postalCode) {
                if (!this.dateObj?.street) this.showToast('Error', 'Please fill Street', 'warning');
                else if (!this.dateObj.city) this.showToast('Error', 'Please fill City', 'warning');
                else if (!this.dateObj.country) this.showToast('Error', 'Please fill Country', 'warning');
                else if (!this.dateObj.postalCode) this.showToast('Error', 'Please fill Postal Code', 'warning');
                this.showSpinner = false;
                return;
            }
        }

        if (!isValid) {
            this.showSpinner = false;
            return;
        }

        if (this.dateObj) {
            createEvent({ dateObj: this.dateObj })
                .then(result => {
                    this.showSpinner = false;

                    if (result === 'Please Complete or Cancel the previous Test Drive before creating a new one.') {
                        this.showToast('Error', result, 'error');
                    } else if (
                        result === 'Event successfully created without dates: ' ||
                        result === 'Event Created Successfully' ||
                        result === 'Event Scheduled Successfully'
                    ) {
                        this.showToast('Success', result, 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        setTimeout(() => {
                            window.location.reload();
                        }, 1000);
                    } else {
                        this.showToast('Error', result, 'error');
                    }
                })
                .catch(error => {
                    console.error("Error: ", error);
                    this.showToast('Error', 'An error occurred while creating the event.', 'error');
                    this.showSpinner = false;
                });
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}