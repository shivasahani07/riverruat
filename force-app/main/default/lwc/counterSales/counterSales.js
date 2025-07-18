import { LightningElement } from 'lwc';
import getAllVehicle from '@salesforce/apex/VehicleController.getAllVehicle';

export default class CounterSales extends LightningElement {
    vrn = '';
    mobile = '';
    vin = '';
    vehicleData = [];
    columns = [
        { label: 'Vehicle Name', fieldName: 'Name' },
        { label: 'Vehicle VRN', fieldName: 'VehicleRegistrationNumber' },
        { label: 'Mobile Number', fieldName: 'CurrentOwner.Phone' },
        { label: 'VIN', fieldName: 'VehicleIdentificationNumber' },
        { label: 'Owner ID', fieldName: 'CurrentOwnerId' },
    ];

    handleInputChange(event) {
        const field = event.target.label;
        if (field === 'Vehicle Registration Number (VRN)') {
            this.vrn = event.target.value;
        } else if (field === 'Mobile Number') {
            this.mobile = event.target.value;
        } else if (field === 'Vehicle Identification Number (VIN)') {
            this.vin = event.target.value;
        }
    }

    handleSearch() {
        getAllVehicle({ mobile: this.mobile, VIN: this.vin, VRN: this.vrn })
            .then(result => {
                this.vehicleData = result;
            })
            .catch(error => {
                console.error('Error fetching vehicles: ', error);
            });
    }

    handleAddProduct() {
        const modalEvent = new CustomEvent('addproduct', {
            detail: { vehicleData: this.vehicleData }
        });
        this.dispatchEvent(modalEvent);
    }
}