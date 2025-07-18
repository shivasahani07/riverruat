import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerFeedbackFormPDF extends LightningElement {
    @api recordId;

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

        const vfUrl = `https://rivermobilityprivatelimited2--rruat--c.sandbox.vf.force.com/apex/CustomerFeedbackForm?id=${this.recordId}`;
        window.open(vfUrl, '_blank');
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    // data = [...Array(100).keys()].map(value => ({ Id: value, value: `Message ${value}` }));
    // scrolled = false;

    // renderedCallback() {
    //     if (!this.scrolled) {
    //         const scrollArea = this.template.querySelector('[data-scroll-area]');

    //         if (scrollArea) {
    //             scrollArea.scrollTop = scrollArea.scrollHeight;

    //             this.scrolled = true;
    //         }
    //     }
    // }

    // get vfUrl() {
    //     return `https://rivermobilityprivatelimited2--rruat--c.sandbox.vf.force.com/apex/CustomerFeedbackForm?id=${this.recordId}`;
    // }

    // handleSave() {
    //     const event = new ShowToastEvent({
    //         title: 'Toast message',
    //         message: 'Toast Message',
    //         variant: 'success',
    //         mode: 'dismissable'
    //     });
    //     this.dispatchEvent(event);
    //     this.dispatchEvent(new CloseActionScreenEvent());
    // }

    // handleCancel() {
    //     this.dispatchEvent(new CloseActionScreenEvent());
    // }   
}