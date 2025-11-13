import { LightningElement } from 'lwc';
import LightningModal from 'lightning/modal';
export default class NewAppointmentFormModal extends LightningModal {

    closeModal() {
        this.close('close');
    }

    handleChildCloseModal() {
        this.closeModal();
    }

}