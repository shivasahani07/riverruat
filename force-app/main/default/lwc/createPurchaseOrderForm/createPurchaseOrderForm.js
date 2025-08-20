import getCurrentLogedUserAccountRecord from '@salesforce/apex/ProductRequestLineController.getCurrentLogedUserAccountRecord';
import userId from '@salesforce/user/Id';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, track,wire } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

import ACCOUNT_FIELD from '@salesforce/schema/User.AccountId';

export default class CreatePurchaseOrderForm extends LightningModal {
   //added by Aniket on 19/08/2025
   userAccountId;

    // Fetch current user's AccountId
    @wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userAccountId = data.fields.AccountId.value;
        } else if (error) {
            console.error('Error fetching user account: ', error);
        }
    }
    //upto here 

    closeModal() {
        this.close('close');
    }

    handleChildCloseModal() {
        this.closeModal();
    }
   @track selectedType = 'Service';

    status = 'New';
    shipmentType = '';
    accountRecordId = '';
    locationRecordId = '';
    selectedType = '';
    deliveryDate='';

    @api purchaseOrderRecordId = {};
    @api POTempObj = {};

    firstScreen = true;
    middleScreen = false;
    secondScreen = false;

    currentUserId;
    userLocationName = '';
    accountName;

    connectedCallback() {
        this.currentUserId = userId;
        this.apexMethod();
    }

    apexMethod() {
        getCurrentLogedUserAccountRecord({ loggedInUserId: this.currentUserId })
            .then(result => {
                if (result && result !== null) {
                    this.accountName = result;
                }
            })
            .catch(error => {
                console.log('Error = ' + error);
            });
    }

    get statusOptions() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Order Placed', value: 'Order Placed' },
            { label: 'Allotted', value: 'Allotted' },
            { label: 'Submitted for Finance Approval', value: 'Submitted for Finance Approval' },
            { label: 'Packing in Progress', value: 'Packing in Progress' },
            { label: 'Dispatch', value: 'Dispatch' },
            { label: 'Recevied', value: 'Recevied' },
            { label: 'Partial Fulfilment', value: 'Partial Fulfilment' },
            { label: 'Complete Fulfilment', value: 'Complete Fulfilment' },
            { label: 'Cancelled', value: 'Cancelled' }
        ];
    }

    get shipmentTypeOptions() {
        return [
            { label: 'VOR', value: 'VOR' },
            { label: 'STK', value: 'STK' }
        ];
    }

    get typeOptions() {
        let options = [
            { label: 'Service', value: 'Service' },
            { label: 'Accessories', value: 'Accessories' }
        ];

        // Add "Merchandise" only if AccountId matches
        if (this.userAccountId === '001F400002SOh0yIAD' || this.userAccountId === '001F400002T242iIAB') {
            options.push({ label: 'Merchandise', value: 'Merchandise' });
        }

        return options;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleShipmentChange(event) {
        this.shipmentType = event.detail.value;

    }
    //added by Aniket on 16/08/2025
    // handleDeliveryDate(event){
    //     debugger;
    //     this.deliveryDate=event.target.value;
    //     console.log('this.deliveryDate=>',this.deliveryDate);

    //     let inputDateValidity = this.template.querySelector('.inputDate');

    //     let rightNow = new Date();
    //     let yyyyMmDd = rightNow.toISOString().slice(0,10);

    //     let today = new Date(yyyyMmDd);
    //     let inputDate = new Date(this.deliveryDate);

    //     if(inputDate < today){
    //         inputDateValidity.setCustomValidity('Choose a future Date');
    //     }else{
    //         inputDateValidity.setCustomValidity('');
    //     }
    //     inputDateValidity.reportValidity();
    // }

    handleSubmitProcess() {
        if (this.shipmentType === '' || this.locationRecordId === null) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill Shipment Type',
                    variant: 'error'
                })
            );
            return;
        }
        //new validation added by Aniket
        // let rightNow = new Date();
        // let yyyyMmDd = rightNow.toISOString().slice(0,10);

        // let today = new Date(yyyyMmDd);
        // let inputDate = new Date(this.deliveryDate);
        // if(inputDate < today){
        //     this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Error',
        //             message: 'Expected Delivery Date Cannot be in past',
        //             variant: 'error'
        //         })
        //     );
        //     return;
        // }
        

        //  let inputDateValidity = this.template.querySelector('.inputDate');
        //  if(this.deliveryDate == ''){
        //    inputDateValidity.setCustomValidity('Choose a Date');
        //    this.dispatchEvent(
        //         new ShowToastEvent({
        //             title: 'Error',
        //             message: 'Expected Delivery Date Cannot be Blank',
        //             variant: 'error'
        //         })
        //     );
        //     return;
        //  }else{
        //     inputDateValidity.setCustomValidity('');
        //  }
        //  inputDateValidity.reportValidity();
         


           

        this.firstScreen = false;
        this.middleScreen = true;
    }

    handleRadioChange(event) {
        debugger;
        this.selectedType = event.detail.value;
        const filterChangeEvent = new CustomEvent('filterchange', {
        detail: this.selectedType
    });
    this.dispatchEvent(filterChangeEvent);
        const obj = {
            shipmentType: this.shipmentType,
            loggedInUserId: this.currentUserId,
            selectedType: this.selectedType,
            deliveryDate: this.deliveryDate//added by Aniket on 16/08/2025

        };

        this.purchaseOrderRecordId = obj;
        this.middleScreen = false;
        this.secondScreen = true;
    }

    handleExit() {
        this.close('close');
    }
}