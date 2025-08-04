import { LightningElement, track, wire } from 'lwc';
import fetchVehicleDetails from '@salesforce/apex/JobCardComponentHelper.fetchVehicleDetails';
import validateOTP from '@salesforce/apex/JobCardComponentHelper.validateOTP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RideRiverLogo from '@salesforce/resourceUrl/RideRiverLogo';
import { getPicklistValues, defaultRecordTypeId, getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import JC_OBJECT from '@salesforce/schema/WorkOrder';
import JOB_TYPE from '@salesforce/schema/WorkOrder.RR_Job_Type__c';
import PERIODIC_TYPE from '@salesforce/schema/WorkOrder.RR_Periodic_Maintenance_Type__c';

import CV_OBJECT from '@salesforce/schema/RR_Customer_Voice__c';
import CONCERN_CATEGORY from '@salesforce/schema/RR_Customer_Voice__c.RR_Concern_Category__c';
import SUB_CATEGORY from '@salesforce/schema/RR_Customer_Voice__c.RR_Sub_Category__c';

import saveCardDetails from '@salesforce/apex/JobCardComponentHelper.saveCardDetails';
import fetchServiceAdvisors from '@salesforce/apex/JobCardComponentHelper.fetchServiceAdvisors';
import getALLVORWithReasonBlank from '@salesforce/apex/JobCardComponentHelper.getAllVORWithReasonBlankWithDetails';
import fetchCities from '@salesforce/apex/JobCardComponentHelper.fetchCities';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
// import { getUserId } from '@salesforce/user/Id';
import getUserId from '@salesforce/user/Id';

export default class RiverJobCard extends NavigationMixin(LightningElement) {
    @track userId = getUserId;
    @track tile1 = true;
    @track inputType = 'VIN';
    @track label = 'VIN';
    @track vehicleIdentifier = '';
    @track phoneNumber = '';
    @track ewSubmitted=false;
    @track vehicleDetails = {
        VehicleIdentificationNumber: '',
        VehicleRegistrationNumber: '',
        EngineNumber: '',
        ModelName: '',
        Purchased_Date__c: '',
        LastOdometerReading: '',
        RR_Battery_Number__c: '',
        IgnitionKeyCode: '',
        CurrentOwnerId: ''
    };
    otpSent = '';
    showOtpInput = false;
    otpEntered = '';
    contact = {
        FirstName: '',
        LastName: '',
        phone: '',
        Email: '',

    };
    showPhoneInput = false;
    showSendOtpButton = false;
    RideRiverLogoUrl = RideRiverLogo + '/my-image.png';
    formattedDate;

    KmsCovered = '';
    contactName = '';
    ToolKit = false;
    RearViewMirror = false;
    VehicleDocument = false;
    FirstAidKit = false;
    Charger = false;
    address = {
        street: '',
        //city: '',
        province: '',
        country: '',
        postalCode: ''
    };
    email = '';
    NonOEAccFitted = false;
    TypeOfJob = '';
    subType = '';
    showSubType = false;
    PersonalBelongings = '';
    AllNonOEAccFitted = '';
    EstimatedCost = 0;
    SOC = 0;
    EstimatedDeliveryTime = '';
    Technician = '';
    OtherObservations = '';
    @track ServiceAdvisor = '';
    @track ServiceAdvisorName = '';
    @track ServiceCenterName = '';
    @track ServiceCenter = '';
    @track CityName = '';
    @track City = '';

    primaryContact = {
        Name: '',
        MailingStreet: '',
        MailingCity: '',
        MailingCountry: '',
        MailingPostalCode: '',
        Phone: '',
        Email: '',
        MailingState: ''

    };
    @track isPrimary = false;
    @track isSecondaryPresent = false;
    @track EstimatedDeliveryTime;
    @track enableFetchButton = true;

    error;
    @track jobtypes;
    @track concernList = [];
    @track concernNoList = [
        { id: 0, serialNumber: 1, Name: '', RR_Concern_Category__c: '', RR_Sub_Category__c: '', RR_Description__c: '', haserror: false, RRConcernCategory: '' }
    ];
    @track disableSave = false;


    @track defaultRecordTypeId;
    @track objectInfoData;
    @track jcObjectDetails;
    @track jobTypeOptions;
    @track periodicFieldData;
    @track periodicTypeOptions;

    //For concern category
    @track concernCategoryOptions;
    @track SubCategoryOptions;
    @track subCategoryFieldData;
    @track cvObjectDetails;
    @track isDisabled;
    @track masterRecordTypeId;

    // Job Card Creation Condtion
    @track isJobCreationAllowed;

    get options() {
        return [
            { label: 'VIN', value: 'VIN' },
            { label: 'Registration Number', value: 'RegistrationNumber' },
        ];
    }

    connectedCallback() {
        debugger;
        // Initialize concernNoList with one row
        this.concernNoList = [
            {
                id: 0,
                serialNumber: 1,
                Name: '',
                RRConcernCategory: '',
                RRSubCategory: '',
                RRDescription: '',
                haserror: false

            }
        ];
        console.log('User ID:-', this.userId);
    }

    ////////////////////////////////////////// Job Type in Job card ///////////////////////////////////////////////////////////////////

    @wire(getObjectInfo, { objectApiName: JC_OBJECT })
    jcObjectInfo({ data, error }) {
        debugger;
        if (data) {
            console.log('JC Object Info loaded successfully:', JSON.stringify(data, null, 2));
            this.jcObjectDetails = data;

            const masterRecordType = Object.values(data.recordTypeInfos).find(
                rt => rt.name === 'Master'
            );

            if (masterRecordType) {
                this.masterRecordTypeId = masterRecordType.recordTypeId;
                console.log('Master Record Type ID:', this.masterRecordTypeId);
            } else {
                console.warn('Master Record Type not found.');
            }
        } else if (error) {
            console.error('Error loading JC Object Info:', JSON.stringify(error, null, 2));
        } else {
            console.warn('No data or error received from getObjectInfo wire.');
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$masterRecordTypeId', fieldApiName: JOB_TYPE })
    jobTypeFieldInfo({ data, error }) {
        if (data) {
            this.jobTypeOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$masterRecordTypeId', fieldApiName: PERIODIC_TYPE })
    periodicTypeFieldInfo({ data, error }) {
        if (data) {
            this.periodicFieldData = data;
            // this.periodicTypeOptions = data.values;
        }
    }

    //added by RAM 13-3-2025
    handleJobTypeChange(event) {
        debugger;
        let name = event.target.name;
        let value = event.target.value;

        this[name] = value;
        let key = this.periodicFieldData.controllerValues[value];
        this.periodicTypeOptions = this.periodicFieldData.values.filter(opt => opt.validFor.includes(key));

        if (name === 'TypeOfJob' && value === 'Periodic maintenance') {
            this.showSubType = true;
        }


        this.updateConcernNoListBasedOnJobType();
    }

    updateConcernNoListBasedOnJobType() {
        this.concernNoList = this.concernNoList.map((item, index) => {
            let updatedItem = { ...item };

            // For VAS Purchase, set concern category to 'General' and update subcategory options
            if (this.TypeOfJob === 'VAS Purchase') {
                updatedItem.RR_Concern_Category__c = 'General';
                updatedItem.RRConcernCategory = 'General';
                updatedItem.isDisabled = true;
                this.updateSubCategoryOptions(updatedItem); // Update subcategory options for VAS Purchase
            } else {

                updatedItem.RR_Concern_Category__c = [];
                updatedItem.RRConcernCategory = '';
                updatedItem.RR_Sub_Category__c = '';
                updatedItem.RRSubCategory = '';
                updatedItem.subCategoryOptions = [];
                updatedItem.isDisabled = false;
            }


            const isNewRow = updatedItem.id === undefined || updatedItem.id === null;

            if (isNewRow) {
                updatedItem.subCategoryOptions = [];
            } else {
                // Preserve subcategory options for existing rows
                updatedItem.subCategoryOptions = updatedItem.subCategoryOptions || [];
            }

            const eventMock = {
                target: {
                    name: 'RRConcernCategory',
                    value: updatedItem.RR_Concern_Category__c,
                    dataset: {
                        name: 'RRConcernCategory',
                        index: index
                    }
                }
            };

            this.handleChange(eventMock);  // Trigger handleChange to update the UI

            return updatedItem;
        });

        this.concernNoList = [...this.concernNoList];  // Ensure reactivity

        console.log('Updated concernNoList after job type change:', JSON.stringify(this.concernNoList));
    }

    //////////////////////////////////////////// Concern category in Customer Voice ///////////////////////////////////////////////////////////////////////////////

    @wire(getObjectInfo, { objectApiName: CV_OBJECT })
    cvObjectInfo({ data, error }) {
        if (data) {
            this.cvObjectDetails = data;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$cvObjectDetails.defaultRecordTypeId', fieldApiName: CONCERN_CATEGORY })
    concernCategoryFieldInfo({ data, error }) {
        if (data) {

            this.concernCategoryOptions = data.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$masterRecordTypeId', fieldApiName: SUB_CATEGORY })
    SubCategoryFieldInfo({ data, error }) {
        if (data) {
            this.subCategoryFieldData = data;
        }
    }

    get currentDate() {
        const today = new Date();
        const day = String(today.getDate()).padStart(2, '0');
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const year = today.getFullYear();
        return `${day}/${month}/${year}`;
    }

    handlechanges(event) {
        const name = event.target.name;
        const value = event.target.value;

        this[name] = value;

        if (name === 'EstimatedDeliveryTime') {
            this.validateDateTime(event.target);
        }

        if (name === 'TypeOfJob' && value === 'Periodic maintenance') {

            let key = this.periodicFieldData.controllerValues[value];

            this.periodicTypeOptions = this.periodicFieldData.values.filter(opt => opt.validFor.includes(key));

            this.showSubType = true;
        }

    }

    validateDateTime(inputElement) {
        const currentDateTime = new Date();
        const inputDateTime = new Date(inputElement.value);

        if (inputDateTime < currentDateTime) {
            inputElement.setCustomValidity('Estimated delivery time cannot be in the past.');
        } else {
            inputElement.setCustomValidity(''); // Clear any previous error
        }

        inputElement.reportValidity();
    }

    handleToggeleChanges(event) {
        this[event.target.name] = event.target.checked;
    }

    handleAddressChanges(event) {
        this.address = event.detail;
    }

    generateRandom4DigitInteger() {
        return Math.floor(Math.random() * (9999 - 1000 + 1)) + 1000;
    }

    handleOtp(event) {
        event.target.setCustomValidity('');
        this.otpEntered = event.target.value;
    }

    handleTypeChange(event) {

        this.inputType = event.target.value;
        if (this.inputType == 'RegistrationNumber') {
            this.label = 'Registration Number';
        } else {
            this.label = 'VIN';
        }
    }

    handleVehicleNumberChange(event) {
        this.vehicleIdentifier = event.target.value;

        if (event.target.value === '' || event.target.value === null || event.target.value === undefined) {
            this.enableFetchButton = true;
        } else {
            this.enableFetchButton = false;
        }

    }

    handlePhoneNumberChange(event) {
        this.phoneNumber = event.target.value;

        // Regular expression to match the specified pattern
        const phonePattern = /^[0-9]{10}$/;

        if (!phonePattern.test(this.phoneNumber)) {
            // If the phone number doesn't match the required format
            event.target.setCustomValidity("Please enter a valid phone number.");
        } else {
            // If the phone number matches the required format, clear any existing validation error
            event.target.setCustomValidity("");
        }

    }

    // fetchVehicleDetails() {
    //     debugger;
    //     getALLVORWithReasonBlank({userid:this.userId}).then(result => {
    //         if (result == true) {
    //             this.showToastMessage('Warning', 'Please update all pending VOR records.', 'warning')
    //             return;
    //         } else {
    //             // Call the Apex method to fetch vehicle details
    //             fetchVehicleDetails({ vehicleIdentifier: this.vehicleIdentifier, inputType: this.inputType })
    //                 .then(result => {
    //                     // Handle successful response
    //                     console.log('vehicle=>', result.vehicle);
    //                     this.vehicleDetails = result.vehicle;

    //                     // Get the phone number of the primary contact
    //                     this.phoneNumber = result.primaryContactPhone;

    //                     if (this.phoneNumber === null || this.phoneNumber === undefined) {
    //                         this.phoneNumber = '';
    //                     }

    //                     this.showToastMessage('Success', 'Vehicle details fetched successfully', 'success');
    //                     this.showPhoneInput = !this.showPhoneInput;
    //                 })
    //                 .catch(error => {
    //                     // Show error message to the user
    //                     console.log('Error in fetching Vehicle ==>', error);
    //                     this.showToastMessage('Error', error.body.message || 'An error occurred', 'error');
    //                 });
    //         }
    //     })
    //         .catch(error => {
    //             console.error('Error fetching VOR:', error);
    //             //  this.isJobCreationAllowed = false;
    //         });

    // }

    fetchVehicleDetails() {
        debugger;
        getALLVORWithReasonBlank({userId:this.userId})
            .then(result => {
                console.log('VOR Result:', result);

                if (result.isOpenVORFound === true) {
                    // Extract VOR numbers from the details array
                    const vorNumbers = result.details?.map(vor => vor.vorNumber).join(', ');

                    // Show in alert
                    // alert('Pending VOR Numbers: ' + vorNumbers);

                    // Optional: Also show a toast
                    this.showToastMessage('Warning',`please update vor reason for vors :${vorNumbers}`, 'warning');
                    return;
                } else {
                    // Call the Apex method to fetch vehicle details
                    fetchVehicleDetails({
                        vehicleIdentifier: this.vehicleIdentifier,
                        inputType: this.inputType
                    })
                        .then(result => {
                            console.log('vehicle =>', result.vehicle);
                            this.vehicleDetails = result.vehicle;
                            this.ewSubmitted = result.vehicle.EW_Submitted__c;//added by Aniket on 31/07/2025
                            this.phoneNumber = result.primaryContactPhone || '';
                            this.showToastMessage('Success', 'Vehicle details fetched successfully', 'success');
                            this.showPhoneInput = !this.showPhoneInput;
                        })
                        .catch(error => {
                            console.error('Error in fetching vehicle:', error);
                            this.showToastMessage('Error', error.body?.message || 'An error occurred', 'error');
                        });
                }
            })
            .catch(error => {
                console.error('Error fetching VOR:', error);
                this.showToastMessage('Error', error.body?.message || 'An error occurred', 'error');
            });
    }



    // Method added By Dinesh : 06/05/2024
    // checkJobCardCreationAllowed() {
    //     debugger;
    //     getALLVORWithReasonBlank().then(result =>{
    //         if (result == false) {
    //             this.isJobCreationAllowed = result;
    //         }else{

    //         }
    //     })
    //     .catch(error => {
    //         console.error('Error fetching VOR:', error);
    //       //  this.isJobCreationAllowed = false;
    //     });
    // }

    sendOTP() {
        // Validate phone number format (10 digits and only numbers)
        const phoneNumberInput = this.template.querySelector('.phonenumberinput');

        const phonePattern = /^[0-9]{10}$/;

        if (!phonePattern.test(this.phoneNumber)) {
            // If the phone number doesn't match the required format
            phoneNumberInput.setCustomValidity("Please enter a valid phone number.");
            phoneNumberInput.reportValidity();
            return;
        } else {

            phoneNumberInput.setCustomValidity("");
            this.otpSent = this.generateRandom4DigitInteger();

            this.otpEntered = this.otpSent;
            this.showOtpInput = !this.showOtpInput;
        }
    }

    handleResendOtp() {
        this.showOtpInput = false;
        this.showResendOtpButton = false;
        this.phoneNumber = '';
        this.otpEntered = '';
        this.otpSent = '';
    }

    verifyOTP() {
        // Validate phone number format (10 digits and only numbers)
        const otp = this.template.querySelector('.otpinput');
        if (this.otpSent == this.otpEntered) {

            validateOTP({ phoneNumber: this.phoneNumber, vehicleDetails: this.vehicleDetails })
                .then(result => {
                    // Handle successful response

                    this.primaryContact = result.primaryCon;
                    this.isSecondaryPresent = result.isSecondaryPresent;
                    this.isPrimary = result.isPrimary;

                    this.contact = result.secondarycon;

                    if (result.secondarycon.Name === null || result.secondarycon.Name === undefined) {
                        this.contactName = '';
                    } else {
                        this.contactName = result.secondarycon.Name;
                    }

                    this.phoneNumber = result.secondarycon.Phone;
                    this.email = result.secondarycon.Email;

                    this.address.city = result.secondarycon.MailingCity;
                    this.address.street = result.secondarycon.MailingStreet;
                    this.address.country = result.secondarycon.MailingCountry;
                    this.address.postalCode = result.secondarycon.MailingPostalCode;
                    this.address.province = result.secondarycon.MailingState;
                    // Do something with the contact object returned
                    this.showToastMessage('Success', 'OTP verified successfully', 'success');
                    this.tile1 = !this.tile1;
                })
                .catch(error => {
                    // Handle error
                    console.error('Error validating OTP:', error.body.message);
                    this.showToastMessage('Error', error.body.message || 'An error occurred', 'error');
                });



            const today = new Date();
            const day = String(today.getDate()).padStart(2, '0');
            const month = String(today.getMonth() + 1).padStart(2, '0');
            const year = today.getFullYear();
            this.formattedDate = `${day}-${month}-${year}`;

        } else {

            otp.setCustomValidity("OTP incorrect");
            otp.reportValidity();
            return;
        }
    }

    //Custom lookup events by SNB 1/07/2024
    /**************************************************************************************************************** */

    @track searchAdvisorsResult;
    @track searchCenterResult = null;
    @track searchKey = '';
    @track centerSearchKey = '';
    @track isSearchLoading = false;
    @track inputErrorMsg = '';
    @track showAdvisorList = false;
    @track showCenterList = false;

    @track searchCityResult = '';
    @track showCityList = false;
    @track CitySearchKey = '';
    @track formattedLocation = '';

    handleSearchChange(event) {
        debugger;
        let name = event.target.name;
        let enteredSearchKey = event.target.dataset.searchkey;
        let storedVariable = event.target.dataset.storedvariable;
        let decider = event.target.dataset.listcontrol;

        //console.log('event.target.dataset1>>',JSON.stringify(event.target.dataset));

        this[enteredSearchKey] = event.target.value;
        if (this[enteredSearchKey].trim() != '' && this[enteredSearchKey].trim().length >= 3) {
            //this[event.target.dataset.listcontrol] = true;
            if (name === "ServiceAdvisorSearch") {
                this.fetchDataOnSearch(this[enteredSearchKey], fetchServiceAdvisors, storedVariable, 'Service Advisor', name, decider);
            }/*else if(name === "ServiceCenterSearch"){
                this.fetchDataOnSearch(this[enteredSearchKey], fetchServiceCenters, storedVariable, 'Service Center', name, decider);
            }*/else if (name === "CitySearch") {
                this.fetchDataOnSearch(this[enteredSearchKey], fetchCities, storedVariable, 'City', name, decider);
            }
        }
        else {
            this[storedVariable] = null;
            this.showInputError('Search requires a minimum of 3 letters.', true, name);
        }
    }

    fetchDataOnSearch(searchKey, apexMethodName, storedVariable, searchingElement, name, decider) {
        debugger;
        //calling apex method
        apexMethodName({ searchKey: searchKey })
            .then(result => {
                debugger;

                if (result == null || result.length == 0) {
                    this.showInputError('No ' + searchingElement + ' Found.', true, name);
                    this[storedVariable] = null;

                }
                else {
                    //console.log('result>>>'+JSON.stringify(result));
                    this.showInputError('', false, name);
                    this[storedVariable] = result;

                    //this.getformattedLocation();
                    this[decider] = true;



                    console.log('showAdvisorList+++>>>>' + this.showAdvisorList);
                }

            })
            .catch(error => {
                console.error('error>>>' + error);
                this.showInputError('Got an error while fetching ' + searchingElement + '.', true, name);
            });
    }

    searchFocusHandler(event) {
        // this[event.target.dataset.listcontrol] = true;
    }

    searchBlurHandler(event) {
        const variableName = event.target.dataset.listcontrol;
        setTimeout(() => {
            this[variableName] = false;
        }, 400);

    }

    selectAdvisor(event) {

        this[event.currentTarget.dataset.listcontrol] = false;
        let variablename = event.currentTarget.dataset.variablename;
        let listName = event.currentTarget.dataset.listname;
        const serviceAdvisorId = event.currentTarget.dataset.id;
        const serviceAdvisorName = event.currentTarget.dataset.name;

        this[event.currentTarget.dataset.namevariable] = serviceAdvisorName;

        this[variablename] = serviceAdvisorId;
        this[listName] = null;

    }

    //showing the error in the fields
    showInputError(errorMsg, isError, searchInputName) {
        this.inputErrorMsg = isError ? errorMsg : '';

        this.template.querySelector(`[data-elementsearch = "${searchInputName}"]`).validity = { valid: !isError };
        this.template.querySelector(`[data-elementsearch = "${searchInputName}"]`).setCustomValidity(errorMsg);
        this.template.querySelector(`[data-elementsearch = "${searchInputName}"]`).reportValidity();
    }

    handleSearchKeyUp(event) {
        event.currentTarget.reportValidity();
    }

    //Custom lookup events by SNB 1/07/2024
    /*****************************************************************************************************************/
    showToastMessage(title, message, variant) {
        // Show toast message to the user
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    //added by Ram 13-03-2025
    addRow() {
        debugger;
        const newId = this.concernNoList.length;

        const newRow = {
            id: newId,
            serialNumber: this.concernNoList.length + 1,
            Name: '',
            RR_Concern_Category__c: this.TypeOfJob === 'VAS Purchase' ? 'General' : '',
            RR_Sub_Category__c: '',
            RR_Description__c: '',
            haserror: false,
            subCategoryOptions: [],
            isDisabled: this.TypeOfJob === 'VAS Purchase'
        };

        this.concernNoList = [...this.concernNoList, newRow];

        console.log('add row list==>' + JSON.stringify(this.concernNoList));

        // 👉 Only update the new row, not all rows
        this.updateSingleConcernNoBasedOnJobType(newRow, this.concernNoList.length - 1);
    }

    // New function to update only the new row
    updateSingleConcernNoBasedOnJobType(item, index) {
        let updatedItem = { ...item };

        if (this.TypeOfJob === 'VAS Purchase') {
            updatedItem.RR_Concern_Category__c = 'General';
            updatedItem.RRConcernCategory = 'General';
            updatedItem.isDisabled = true;
            this.updateSubCategoryOptions(updatedItem);
        } else {
            updatedItem.RR_Concern_Category__c = '';
            updatedItem.RRConcernCategory = '';
            updatedItem.RR_Sub_Category__c = '';
            updatedItem.RRSubCategory = '';
            updatedItem.subCategoryOptions = [];
            updatedItem.isDisabled = false;
        }

        // Update row in the list directly
        this.concernNoList[index] = updatedItem;

        // Mock event to trigger UI update
        const eventMock = {
            target: {
                name: 'RRConcernCategory',
                value: updatedItem.RR_Concern_Category__c,
                dataset: {
                    name: 'RRConcernCategory',
                    index: index
                }
            }
        };

        this.handleChange(eventMock);

        this.concernNoList = [...this.concernNoList]; // Ensure reactivity
    }

    //Added By RAM 13-03-2025
    updateSubCategoryOptions(item) {
        if (item.RR_Concern_Category__c) {

            let key = this.subCategoryFieldData.controllerValues[item.RR_Concern_Category__c];


            let options = this.subCategoryFieldData.values.filter(opt => opt.validFor.includes(key));


            item.subCategoryOptions = options;
        } else {
            item.subCategoryOptions = [];
        }
    }

    handleChange(event) {
        debugger;
        const name = event.target.dataset.name;
        const index = event.target.dataset.index;

        this.concernNoList[index][name] = event.target.value;
        console.log('Updated Sub Category:', this.concernNoList[index].RRSubCategory);

        if (name === "RRConcernCategory") {

            let key = this.subCategoryFieldData.controllerValues[event.target.value];

            let options = this.subCategoryFieldData.values.filter(opt => opt.validFor.includes(key));


            this.concernNoList[index]["subCategoryOptions"] = options;
        }

        this.concernNoList = [...this.concernNoList];

        let hasduplicate = this.checkForDuplicates();

    }

    //to check the duplicats in the concern List
    checkForDuplicates() {
        const categories = new Set();
        let hasDuplicates = false;

        this.concernNoList = this.concernNoList.map((item, index) => {
            const categoryKey = `${item.RRConcernCategory}-${item.RRSubCategory}`;

            if (categories.has(categoryKey)) {
                hasDuplicates = true;
                return { ...item, haserror: true };
            } else {
                categories.add(categoryKey);
                return { ...item, haserror: false };
            }
        });

        return hasDuplicates;
    }

    deleteRow() {
        if (this.concernNoList.length > 1) {
            this.concernNoList.pop();
            this.concernNoList = [...this.concernNoList];
        }
    }

    // Updating serial numbers dynamically
    updateSerialNumbers() {
        this.concernNoList = this.concernNoList.map((item, index) => {
            return { ...item, serialNumber: index + 1 };
        });
    }

    handleSubmit() {
        debugger;
        const elements = this.template.querySelectorAll('.validate');
        let proceed = true;
        
        
        // Iterate over each element and check validity
        elements.forEach(element => {
            element.reportValidity();

            if (!element.reportValidity()) {
                proceed = false;
                element.reportValidity();
                element.focus();

                return;
            }
        });

        if(this.TypeOfJob=='' || this.TypeOfJob==null){
                this.showToastMessage('alert', 'Please Select Job Type', 'alert');
                return;
        }

        let hasduplicate = this.checkForDuplicates();

        if (hasduplicate === true) {
            proceed = false;
        }

        console.log('this.ServiceAdvisor>>>' + this.ServiceAdvisor);
        //console.log('this.City>>>' + this.City);
        console.log('Sub Category before Save:', this.concernNoList[0].RRSubCategory);
        // console.log('this.ServiceCenter>>>'+this.ServiceCenter);

        // this.ServiceAdvisor,

        if (this.ServiceAdvisor === undefined || this.ServiceAdvisor === null || this.ServiceAdvisor === '') {
            LightningAlert.open({
                message: 'Please selct a Service Advisor correctly! (Search and select from the drop down)',
                theme: 'warning',
                label: 'Error!'
            });
        }

        if (proceed) {

            this.disableSave = true;

            // Proceed with the task

            const jobCardDetails = {
                inputType: this.inputType,
                vehicleIdentifier: this.vehicleIdentifier,
                vehicle: this.vehicleDetails,
                phoneNumber: this.phoneNumber,
                KmsCovered: this.KmsCovered,
                contactName: this.contactName,
                contact: this.contact,
                ToolKit: this.ToolKit,
                RearViewMirror: this.RearViewMirror,
                VehicleDocument: this.VehicleDocument,
                FirstAidKit: this.FirstAidKit,
                Charger: this.Charger,
                address: this.address,
                email: this.email,
                NonOEAccFitted: this.NonOEAccFitted,
                TypeOfJob: this.TypeOfJob,
                subType: this.subType,
                PersonalBelongings: this.PersonalBelongings,
                AllNonOEAccFitted: this.AllNonOEAccFitted,
                EstimatedCost: this.EstimatedCost,
                SOC: this.SOC,
                EstimatedDeliveryTime: this.EstimatedDeliveryTime,
                Technician: this.Technician,
                OtherObservations: this.OtherObservations,
                concernNoList: this.concernNoList,
                // ServiceCenter: this.ServiceCenter,
                ServiceAdvisor: this.ServiceAdvisor,
                //city: this.City,
                // RR_Concern_Category__c: this.RRConcernCategory
            };

            console.log('Job card Detail==>' + JSON.stringify(jobCardDetails));
            console.log('concernNoList==>' + JSON.stringify(this.concernNoList));

            // Call the Apex method
            saveCardDetails({ jobCardDetails: jobCardDetails })
                .then(result => {
                    debugger;
                    this.showToastMessage('Success', 'JobCard created successfully', 'success');

                    const recordId = result;

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: recordId,
                            objectApiName: 'WorkOrder',
                            actionName: 'view'
                        },
                    })
                })
                .catch(error => {

                    this.disableSave = false;

                    this.showToastMessage('Error', error.body.message || 'An error occurred', 'error');
                });

        }

    }

}