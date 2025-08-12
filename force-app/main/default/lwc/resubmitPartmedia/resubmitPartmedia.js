import { LightningElement, api, wire, track } from 'lwc';
import getDiscrepancyLineItems from '@salesforce/apex/ResubmitDiscrepancyMediaController.getDiscrepancyLineItems';
import updateMediaUrls from '@salesforce/apex/ResubmitDiscrepancyMediaController.updateMediaUrls';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class DiscrepancyMedia extends LightningElement {
    @api recordId;
    @track lineItems = [];
   // @track showapinner = False;
    error;

    @wire(getDiscrepancyLineItems, { shipmentId: '$recordId' })
    wiredItems({ error, data }) {
        debugger
        console.log(this.recordId);
        if (data) {
            this.lineItems = data.map(item => ({ ...item }));
           // this.showapinner = True;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
        }
    }

    handleUrlChange(event) {
        const itemId = event.target.dataset.id;
        const newUrl = event.target.value;
        this.lineItems = this.lineItems.map(item =>
            item.Id === itemId ? { ...item, Supporting_Media__c	: newUrl } : item
        );
    }

    handleSave() {
        debugger;
        //this.showapinner = True;
        updateMediaUrls({ items: this.lineItems })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Media URLs updated successfully',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
                setTimeout(() => {
                    window.location.reload();
                }, 500);;
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
               // this.showapinner = False;
            });
    }
}