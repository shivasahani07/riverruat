import { LightningElement, api, track } from 'lwc';
import getAvailableSlots from '@salesforce/apex/AppointmentFormController.getAvailableSlots';
import getSlotItemsBySlotId from '@salesforce/apex/AppointmentFormController.getSlotItemsBySlotId';
import AllotBookingSlot from '@salesforce/apex/AppointmentFormController.AllotBookingSlot';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class CreateAppointmentSlotItem extends LightningElement {

    @api recordId;
    @track slotOptions = [];
    @track slotItemOptions = [];
    selectedSlot;
    startTime = '';
    endTime = '';
    selectedSlotItem;
    error;
    @track isLoading = false;

   connectedCallback() {
    this.isLoading = true;
    getAvailableSlots({ appointmentId: this.recordId })
        .then(result => {
            this.slotOptions = result.map(slot => ({
                label: slot.Name,
                value: slot.Id
            }));
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        })
        .finally(() => {
            this.isLoading = false; 
        });
    }


    handleSlotChange(event) {
        debugger;
        this.selectedSlot = event.detail.value;
        this.slotItemOptions = [];
        if (this.selectedSlot) {
            getSlotItemsBySlotId({ slotId: this.selectedSlot })
                .then(result => {
                    this.slotItemOptions = result.map(item => {
                        const start = this.formatMillisecondsToTime(item.Start_Time__c);
                        const end = this.formatMillisecondsToTime(item.End_Time__c);
                        return {
                            label: `${start} - ${end}`,
                            value: item.Id
                        };
                    });
                    console.log('Slot Item Options => ', this.slotItemOptions);
                })
                .catch(error => {
                    this.showToast('Error fetching slot items', error.body.message, 'error');
                });
        }
    }

    formatMillisecondsToTime(ms) {
        if (typeof ms !== 'number') return '';
        const totalSeconds = ms / 1000;
        const hours24 = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = Math.floor(totalSeconds % 60);
        const suffix = hours24 >= 12 ? 'PM' : 'AM';
        const hours12 = hours24 % 12 || 12;
        const pad = (num) => num.toString().padStart(2, '0');
        return `${hours12}:${pad(minutes)}:${pad(seconds)} ${suffix}`;
    }

    handleSlotItemChange(event) {
        debugger;
        this.selectedSlotItem = event.detail.value;
    }

    handleStartTime(event) {
        this.startTime = event.detail.value;
    }

    handleEndTime(event) {
        this.endTime = event.detail.value;
    }

    handleSave() {
        debugger;
        AllotBookingSlot({ AppointmentId: this.recordId, AppoSlotId: this.selectedSlot,AppSItemId : this.selectedSlotItem }).then(result => {
            if (result && result === 'success') {
                this.showToast('SUCCESS', 'Booking slot has been successfully confirmed.','success');
                this.handleCancel();
            } else {
                this.showToast('ERROR',result,'error');
            }
        })
            .catch(error => {
                console.log('Error === >' + this.error);
            })
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    get canShowSubmit() {
        return this.selectedSlot && this.selectedSlotItem;
    }

}