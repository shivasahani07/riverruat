import { LightningElement, track, api } from 'lwc';
import getLineItemsForShipment from '@salesforce/apex/DiscrepancyLotController.getLineItemsForShipment';
import createDiscrepancyLot from '@salesforce/apex/DiscrepancyLotController.createDiscrepancyLot';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class CreateDiscrepancyLotForm extends LightningElement {
    @track handoverPerson = '';
    @track requesterName = '';
    @track phoneNumber = '';
    @track dispatcheDate ;
    @track lrnumber;
    @track purpose = '';
    @track lineItems = [];
    @track selectedLineItems = [];
    @api recordId;
    //@track showSpinner = False;
    connectedCallback() {
        debugger;
        if (!this.recordId) {
            const url = window.location.href;
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));

            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    this.recordId = recordIdKeyValue[1];
                }
            } else {
                const match = url.match(/\/Shipment\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                }
            }
        }
    }


    transportOptions = [
        { label: 'Air', value: 'Air' },
        { label: 'Road', value: 'Road' }
    ];
    addressOptions = [
        { label: 'River Factory', value: 'River Factory' },
        { label: 'River HQ', value: 'River HQ' }
    ];
    columns = [
        { label: 'Discrepancy Line Item', fieldName: 'Name' },
        { label: 'Product Name', fieldName: 'Product_Name__c' },
        { label: 'Shipment', fieldName: 'Shipment__c' },
        { label: 'Discrepancy', fieldName: 'DiscrepancyName' },
        { label: 'Quantity', fieldName: 'Quantity__c', type: 'number' },
        { label: 'Claimed Amount', fieldName: 'Claimed_Amount__c' }
    ];

    handleChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
    }

    handleLoadLineItems() {
        debugger;
        getLineItemsForShipment({ shipmentId: this.recordId })  // this.recordId must be set to current Shipment Id
            .then(result => {
                this.lineItems = result.map(item => ({
                    ...item,
                    DiscrepancyName: item.Discrepancy__r?.Name || ''
                }));
            })
            .catch(error => {
                console.error('Error fetching line items:', error);
            });
    }

    handleRowSelection(event) {
        this.selectedLineItems = event.detail.selectedRows;
    }

    handleSave() {
        debugger;
        //this.showSpinner = true;
        if (!this.handoverPerson || !this.requesterName || !this.phoneNumber || !this.purpose) {
            this.showToast('Missing Data', 'Please fill in all fields.', 'warning');
            return;
        }

        if (this.selectedLineItems.length === 0) {
            this.showToast('No Items Selected', 'Please select at least one line item.', 'warning');
            return;
        }

        const lineItemIds = this.selectedLineItems.map(item => item.Id);

        createDiscrepancyLot({
            handoverPerson: this.handoverPerson,
            requesterName: this.requesterName,
            phone: this.phoneNumber,
            dispathcdate : this.dispatcheDate,
            lrnumber : this.lrnumber,
            purpose: this.purpose,
            addressOfConsignee: this.addressOfConsignee,
            modeOfTransport: this.modeOfTransport,
            lineItemIds: lineItemIds
        })
            .then(lotId => {
                this.showToast('Success', 'Discrepancy Lot created successfully.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
               // this.showSpinner = False;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
           // this.showSpinner = true;
    }

    handleCancel() {
        this.handoverPerson = '';
        this.requesterName = '';
        this.phoneNumber = '';
        this.dispatcheDate = '';
        this.purpose = '';
        this.lineItems = [];
        this.selectedLineItems = [];
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}