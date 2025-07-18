import { LightningElement, track } from 'lwc';
import { ShowToastEvent }       from 'lightning/platformShowToastEvent';
import createSlot               from
   '@salesforce/apex/AppointmentSlotController.createSlot';

export default class CreateAppointmentSlot extends LightningElement {

    serviceCenterId;
    @track slotDate;
    @track slotDuration;

    handleCenterSelected(event) {
        this.serviceCenterId = event.detail.recordId;
    }

    handleInputChange(event) {
        if (event.target.name === 'slotDate') {
            this.slotDate = event.target.value;
        } else if (event.target.name === 'slotDuration') {
            this.slotDuration = event.target.value;
        }
    }

    get disableSave() {
        return !(this.serviceCenterId && this.slotDate && this.slotDuration);
    }

    createSlots() {
        createSlot({
            serviceCenterId : this.serviceCenterId,
            slotDate        : this.slotDate,
            slotDurationMins: parseInt(this.slotDuration, 10)
        })
        .then(() => {
            this.showToast('Success',
                           'Appointment slot and items created.',
                           'success');
            this.clearForm();
        })
        .catch(error => {
            this.showToast('Error', this.reduceErrors(error).join(', '), 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    clearForm() {
        this.slotDate     = null;
        this.slotDuration = null;
        this.serviceCenterId = null;

        const picker = this.template.querySelector('lightning-record-picker');
        if (picker) picker.reset();
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) { errors = [errors]; }
        return errors
            .filter(e => !!e)
            .map(e => e.body ? e.body.message : e.message);
    }
}