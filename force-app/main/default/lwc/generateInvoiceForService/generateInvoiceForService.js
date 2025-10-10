import { LightningElement, api, track } from 'lwc';
import Successinvoice from '@salesforce/resourceUrl/Successinvoice';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import generateInvoicePDF from '@salesforce/apex/GenerateInvoiceForServicePDF.generateInvoicePDF';

export default class GenerateInvoiceForService extends LightningElement {
    @api recordId;
    @track loading = true;
    @track success = false;
    Successinvoice = Successinvoice;

    connectedCallback() {
        // Extract recordId from URL if not passed
        debugger;
            const url = window.location.href.toString();
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));
            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    const recordId = recordIdKeyValue[1];
                    this.recordId = recordId;
                } else {
                    console.error("Invalid recordId parameter format");
                }
            } else {
                console.error("recordId parameter not found in the URL");
            }
            if (this.recordId == undefined || this.recordId == null) {
                if (this.recordId == undefined) {
                    const url = window.location.href;
                    const match = url.match(/\/WorkOrder\/([^/]+)/);
                    if (match) {
                        this.recordId = match[1];
                        console.log('Record Id:', this.recordId);
                    }
                }
                this.recordId = this.recordId;
            }

        if (this.recordId) {
            this.generateInvoice();
        } else {
            this.showToast('Error', 'Record Id not found', 'error');
            this.loading = false;
        }
    }

        generateInvoice() {
        this.loading = true;
        generateInvoicePDF({ recordId: this.recordId })
            .then(result => {
                if (result === 'success') {
                    this.success = true;
                    this.showToast('Success', 'Invoice generated successfully', 'success');
                    this.loading = false;

                    // Immediately close the modal after showing toast
                    this.handleCancel();

                } else {
                    this.showToast('Error', result, 'error');
                    this.loading = false;
                }
            })
            .catch(error => {
                this.showToast('Error', error.body ? error.body.message : error.message, 'error');
                this.loading = false;
            });
    }


    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}