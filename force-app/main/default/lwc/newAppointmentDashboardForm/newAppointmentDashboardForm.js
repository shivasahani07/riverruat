import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

import getVehiclesByContact from '@salesforce/apex/NewAppointementFormController.getVehicleRegByContact';
import getVehicleByVIN from '@salesforce/apex/NewAppointementFormController.getVehicleByVIN';
import getCurrentServiceCenter from '@salesforce/apex/NewAppointementFormController.getCurrentServiceCenter';
import getPicklistValues from '@salesforce/apex/NewAppointementFormController.getPicklistValues';
import getSlotItems from '@salesforce/apex/NewAppointementFormController.getSlotItems';
import createAppointmentforServiceAppointment from '@salesforce/apex/NewAppointementFormController.createAppointmentforServiceAppointment';

export default class NewAppointmentDashboardForm extends NavigationMixin(LightningElement) {
    @api recordId;

    @track showSearchView = true;
    @track showForm = false;
    @track searchContact = '';
    @track vehiclesList = [];
    @track vehicleOptions = [];
    @track selectedVehicleId = '';
    @track isLoading = false;
    @track searchMade = false;

    @track vrn = '';
    @track vin = '';
    @track dealerName = '';
    @track milestoneDate = '';
    @track milestoneId = '';
    @track contactNumber = '';
    @track serviceCenterId = '';
    @track serviceCenterName = '';
    @track selectedValue = '';
    @track appointmentDate = '';
    @track selectedSlotItem = '';
    @track slotItemOptions = [];
    @track appointmentDecription = '';
    @track slotsAvailable = false;
    @track showDescriptionField = false;
    @track showVrnError = false;
    minDate;

    @track options = [];

    connectedCallback() {
        this.setMinDate();
        this.loadPicklistValues();
    }

    @wire(getCurrentServiceCenter)
    wiredCenterName({ data, error }) {
        if (data) {
            this.serviceCenterId = data.accountId;
            this.serviceCenterName = data.accountName;
        } else if (error) {
            console.error('Error fetching service center', error);
        }
    }

    setMinDate() {
        const today = new Date();
        this.minDate = today.toISOString().split('T')[0];
    }

    loadPicklistValues() {
        getPicklistValues({
            objectApiName: 'ServiceAppointment',
            fieldApiName: 'Type_Of_Requested_Services__c'
        })
            .then(result => {
                this.options = result.map(value => ({ label: value, value }));
            })
            .catch(error => console.error('Error loading picklist', error));
    }

    handleContactChange(e) {
        this.searchContact = e.target.value;
    }

    get isSearchDisabled() {
        return !this.searchContact || this.isLoading;
    }

    handleContactSearch() {
        if (!this.searchContact) {
            this.showToast('Warning', 'Enter contact number to search', 'warning');
            return;
        }

        this.isLoading = true;
        getVehiclesByContact({ contactnumber: this.searchContact })
            .then(data => {
                this.searchMade = true;
                if (data?.length) {
                    this.vehiclesList = data;
                    this.vehicleOptions = data.map(v => ({
                        label: `${v.VehicleRegistrationNumber || ''} (${v.VehicleIdentificationNumber || ''})`,
                        value: v.Id
                    }));
                } else {
                    this.vehiclesList = [];
                }
            })
            .catch(error => {
                console.error(error);
                this.showToast('Error', 'Error fetching vehicles', 'error');
            })
            .finally(() => (this.isLoading = false));
    }

    handleVehicleSelect(e) {
        this.selectedVehicleId = e.detail.value;
    }

    get isContinueDisabled() {
        return !this.selectedVehicleId;
    }

    handleSelectVehicleContinue() {
        const vehicle = this.vehiclesList.find(v => v.Id === this.selectedVehicleId);
        if (!vehicle) return;

        this.vrn = vehicle.VehicleRegistrationNumber;
        this.vin = vehicle.VehicleIdentificationNumber;
        this.contactNumber = this.searchContact;

        // show error if VRN missing
        this.showVrnError = !this.vrn;

        this.showSearchView = false;
        this.showForm = true;

        // Fetch milestone details by VIN
        this.fetchVehicleDetailsByVIN();
    }

    handleBackToSearch() {
        this.showForm = false;
        this.showSearchView = true;
        this.showVrnError = false;
    }

    fetchVehicleDetailsByVIN() {
        if (!this.vin) return;

        getVehicleByVIN({ vin: this.vin })
            .then(data => {
                if (data) {
                    this.dealerName = data.DealerName || '';
                    this.milestoneDate = data.MilestoneDate || '';
                    this.milestoneId = data.MilestoneId || '';
                }
            })
            .catch(err => console.error('Error fetching VIN details', err));
    }

    handleSelectServices(e) {
        this.selectedValue = e.detail.value;
    }

    handleDateChange(e) {
        this.appointmentDate = e.target.value;
        this.loadSlotItems();
    }

    loadSlotItems() {
        if (!this.serviceCenterId || !this.appointmentDate) return;

        this.isLoading = true;
        getSlotItems({
            serviceCenterId: this.serviceCenterId,
            appointmentDate: this.appointmentDate
        })
            .then(res => {
                this.appointmentSlotIds = res.slotIds || [];
                const items = (res.slotItems || []).map(i => {
                    const start = new Date(i.Start_Time__c);
                    const end = new Date(i.End_Time__c);
                    const options = { hour: '2-digit', minute: '2-digit', hour12: true };
                    return {
                        label: `${i.Name} | ${start.toLocaleTimeString([], options)} - ${end.toLocaleTimeString([], options)}`,
                        value: i.Id
                    };
                });
                this.slotItemOptions = items;
                this.slotsAvailable = items.length > 0;
                this.showDescriptionField = this.slotsAvailable;
                this.selectedSlotItem = '';
            })
            .catch(err => {
                this.showToast('Error', err?.body?.message || 'Failed to load slot items', 'error');
            })
            .finally(() => (this.isLoading = false));
    }

    handleSlotItemChange(e) {
        this.selectedSlotItem = e.detail.value;
    }

    handleAppointmentDesc(e) {
        this.appointmentDecription = e.detail.value;
    }

    handleSubmit() {
        if (this.isSubmitDisabled) {
            this.showToast('Warning', 'Please fill all fields', 'warning');
            return;
        }

        this.isLoading = true;
        createAppointmentforServiceAppointment({
            serviceAppId: this.recordId,
            accountId: this.serviceCenterId,
            vrn: this.vrn,
            appointmentDate: this.appointmentDate,
            contactNumber: this.contactNumber,
            serviceType: this.selectedValue,
            slotId: this.appointmentSlotIds?.[0] || null,
            slotItemId: this.selectedSlotItem,
            appointmentDecription: this.appointmentDecription,
            milestoneId: this.milestoneId
        })
            .then(appId => {
                this.showToast('Success', 'Appointment created successfully', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
                this.closeModal();
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: appId,
                        objectApiName: 'Appointment__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(err => {
                this.showToast('Error', err?.body?.message || 'Error creating appointment', 'error');
            })
            .finally(() => (this.isLoading = false));
    }

    get isSubmitDisabled() {
        return !(
            this.vrn &&
            this.contactNumber &&
            this.appointmentDate &&
            this.selectedSlotItem &&
            this.selectedValue
        );
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasVehicles() {
        return this.vehiclesList?.length > 0;
    }

    closeModal() {
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
    }
}