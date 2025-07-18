import { LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class BatchRecordLwcModal extends LightningModal {
     closeModal() {
        this.close('close');
    }

    handleChildCloseModal() {
        this.closeModal();
    }
}