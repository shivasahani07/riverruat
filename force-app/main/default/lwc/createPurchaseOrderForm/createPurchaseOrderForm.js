import getCurrentLogedUserAccountRecord from '@salesforce/apex/ProductRequestLineController.getCurrentLogedUserAccountRecord';
import userId from '@salesforce/user/Id';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, track } from 'lwc';

export default class CreatePurchaseOrderForm extends LightningModal {
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
        return [
            { label: 'Service', value: 'Service' },
            { label: 'Merchandise', value: 'Merchandise' },
            { label: 'Accessories', value: 'Accessories' }
        ];
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleShipmentChange(event) {
        this.shipmentType = event.detail.value;
    }

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
            selectedType: this.selectedType
        };

        this.purchaseOrderRecordId = obj;
        this.middleScreen = false;
        this.secondScreen = true;
    }

    handleExit() {
        this.close('close');
    }
}