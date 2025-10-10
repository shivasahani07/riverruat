import { api, LightningElement, track } from 'lwc';
import generateProforma from '@salesforce/apex/ProformaInvoiceController.generateProforma';
import getOrderStatus from '@salesforce/apex/ProformaInvoiceController.getOrderStatus';
import { CloseActionScreenEvent } from 'lightning/actions';
import Successinvoice from '@salesforce/resourceUrl/Successinvoice';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class GenerateProformaInvoice extends LightningElement {

    @api recordId;
    @track isLoading = true;
    Successinvoice = Successinvoice;
    closeImmediately = false;

    connectedCallback() {
        setTimeout(() => {
            this.isLoading = true;
        }, 0);

        this.extractRecordIdFromUrl();

        if (this.recordId) {
            this.checkOrderStatus();
        } else {
            this.isLoading = false;
            this.showToast('Error', 'Record Id not found.', 'error');
        }
    }

    extractRecordIdFromUrl() {
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
            const match = url.match(/\/order\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            } else {
                console.error("recordId not found in URL");
            }
        }
    }

    checkOrderStatus() {
        getOrderStatus({ recordId: this.recordId })
            .then(status => {
                this.callApexMethod();
                // if (status === 'Pre Invoice') {
                // } else {
                //     this.isLoading = false;
                //     this.showToast(
                //         'Error',
                //         'Please move the Order Stage to Pre Invoice to generate Proforma.',
                //         'error'
                //     );
                //     this.dispatchEvent(new CloseActionScreenEvent());
                // }
            })
            .catch(error => {
                console.error('Error fetching order status:', error);
                this.isLoading = false;
                this.showToast('Error', 'Unable to fetch order status.', 'error');
            });
    }

    callApexMethod() {
        generateProforma({ recordId: this.recordId })
            .then(result => {
                if (result && result.includes('SUCCESS')) {
                    this.isLoading = false;

                    setTimeout(() => {
                        this.showToast('Success', 'Proforma Invoice generated successfully.', 'success');
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }, 1000);
                } else {
                    this.showToast('Error', result || 'Unknown error occurred.', 'error');
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('Apex Error: ', error);
                this.showToast('Error', error.body?.message || 'Unknown error occurred.', 'error');
                this.isLoading = false;
            });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        }));
    }
}