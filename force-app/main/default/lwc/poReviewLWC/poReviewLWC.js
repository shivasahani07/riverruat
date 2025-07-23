import { LightningElement, api, track, wire } from 'lwc';
import getPOLineItems from '@salesforce/apex/POReviewCompController.getPOLineItems';
import updatePOLineItems from '@salesforce/apex/POReviewCompController.updatePOLineItems';
import softDeleteLineItem from '@salesforce/apex/POReviewCompController.softDeleteLineItem';
import getAllProducts from '@salesforce/apex/POReviewCompController.getAllProducts';
import markPOSubmitted from '@salesforce/apex/POReviewCompController.markPOSubmitted';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class POReviewLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track lineItems = [];
    @track isLoading = true;
    @track selectedProductId;
    @track newQty;
    @track productOptions = [];
    @track productMap = {};

    statusOptions = [
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    

    @wire(getPOLineItems, { poId: '$recordId' })
    wiredLineItems({ data, error }) {
        if (data) {
            this.lineItems = data.map(item => ({
                ...item,
                updatedQuantity: item.QuantityRequested,
                approvalStatus: item.ApprovalStatus || 'Pending'
            }));
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Error fetching line items:', error);
        }
    }

    @wire(getAllProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.productOptions = data.map(prod => ({
                label: prod.Name,
                value: prod.Id
            }));

            this.productMap = {};
            data.forEach(prod => {
                this.productMap[prod.Id] = {
                    name: prod.Name,
                    moq: prod.Minimum_Order_Qty__c
                };
            });
        } else if (error) {
            console.error('Error loading products:', error);
        }
    }

    handleQuantityInputChange(event) {
        const index = event.target.dataset.index;
        const newVal = parseFloat(event.target.value);
        if (newVal < this.lineItems[index].ForecastQty) {
            this.showToast('Error', 'Cannot reduce below forecast quantity.', 'error');
            this.lineItems[index].updatedQuantity = this.lineItems[index].ForecastQty;
        } else {
            this.lineItems[index].updatedQuantity = newVal;
        }
    }

    handleStatusChange(event) {
        const index = event.target.dataset.index;
        this.lineItems[index].approvalStatus = event.detail.value;
    }

    handleDelete(event) {
        const index = event.target.dataset.index;
        const lineItemId = event.target.dataset.id;
        softDeleteLineItem({ lineItemId })
            .then(() => {
                this.lineItems.splice(index, 1);
                this.lineItems = [...this.lineItems];
                this.showToast('Success', 'Line item deleted', 'success');
            });
    }

    handleProductSelection(event) {
        this.selectedProductId = event.detail.value;

        if (this.productMap[this.selectedProductId]) {
            this.newQty = this.productMap[this.selectedProductId].moq;
        } else {
            this.newQty = null;
        }
    }

    handleNewQtyChange(event) {
        this.newQty = event.detail.value;
    }

    handleAddManualItem() {
        const selected = this.productOptions.find(opt => opt.value === this.selectedProductId);
        if (!selected || !this.newQty) return;

        this.lineItems.push({
            Id: null,
            Product2Id: this.selectedProductId,
            ProductName: selected.label,
            ForecastQty: 0,
            updatedQuantity: parseInt(this.newQty),
            approvalStatus: 'Approved',
            isNew: true
        });

        this.selectedProductId = null;
        this.newQty = null;
    }

    handleSave() {
        const payload = this.lineItems.map(item => ({
            Id: item.Id,
            Product2Id: item.Product2Id,
            QuantityRequested: item.updatedQuantity,
            IsNew: item.isNew,
            // ApprovalStatus: 'Submitted',
        }));

        return updatePOLineItems({ poId: this.recordId, jsonString: JSON.stringify(payload) })
            .then(() => {
                this.showToast('Success', 'PO updated successfully', 'success');
                this.navigateBack();
            })
            .catch(err => {
                //this.showToast('Error', 'Update failed', 'error');
            });
    }

    handleSubmit() {
        // Send the Email and Notification
        
        /*
        const pendingOrRejected = this.lineItems.some(item => item.approvalStatus !== 'Approved');
        if (pendingOrRejected) {
            this.showToast('Error', 'Only approved items can be submitted.', 'error');
            return;
        }
        */

        // Save line items, then mark PO as submitted
        this.handleSave().then(() => {
            markPOSubmitted({ poId: this.recordId  })
                .then(() => {
                    this.showToast('Success', 'PO Submitted Successfully', 'success');

                    // Optionally refresh view
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                })
                .catch(error => {
                    console.error('Submit Error -->', JSON.stringify(error));
                    //this.showToast('Error', 'Failed to mark PO as submitted: ' + this.parseError(error), 'error');
                });
        });

    }

    parseError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Unknown error occurred.';
    }

    navigateBack() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'ProductRequest',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}