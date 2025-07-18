import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import Customer_Concern__c from '@salesforce/schema/Customer_Concern__c';
import Type__c from '@salesforce/schema/Customer_Concern__c.Type__c';
import Case_Category__c from '@salesforce/schema/Customer_Concern__c.Case_Category__c';
import Concerns__c from '@salesforce/schema/Customer_Concern__c.Concerns__c';
import Case__c from '@salesforce/schema/Customer_Concern__c.Case__c';//added by Aniket on 25/04/2025
import Subconcerns__c from '@salesforce/schema/Customer_Concern__c.Subconcerns__c';
import VOC__c from '@salesforce/schema/Customer_Concern__c.VOC__c';
import getAllVehicle from '@salesforce/apex/customerConcernController.getAllVehicle';
import getRecentCases from '@salesforce/apex/customerConcernController.getRecentCases';
import getJobCardList from '@salesforce/apex/customerConcernController.getJobCardList';
import getAccountList from '@salesforce/apex/customerConcernController.getAccountList';

import { NavigationMixin } from 'lightning/navigation';//added by Aniket on 28/04/2025
import Case_Category_Update__c from '@salesforce/schema/Customer_Concern__c.Case_Category_Update__c';//added by Aniket on 28/04/2025


import { getRecord } from 'lightning/uiRecordApi';//added by Aniket on 25/04/2025
import Case from '@salesforce/schema/Case';
import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';//added by Aniket on 25/04/2025
import Case_Type__c from '@salesforce/schema/Case.Case_Type__c';
import Assign_to_Dealer__c from '@salesforce/schema/Case.AccountId';
import Vehicle__c from '@salesforce/schema/Case.Vehicle__c';
import Subject from '@salesforce/schema/Case.Subject';
import AccountId from '@salesforce/schema/Case.AccountId';
import SuppliedEmail from '@salesforce/schema/Case.SuppliedEmail';
import SuppliedName from '@salesforce/schema/Case.SuppliedName';
import SuppliedPhone from '@salesforce/schema/Case.SuppliedPhone';

export default class CreateCustomerConcern extends NavigationMixin(LightningElement) {
    @track customerConcerns = [];
    @track typeOptions = [];
    @track categoryOptions = [];
    @track concernOptions = [];
        
    @track subconcernOptions = [];
  
    @track department;
    @track selectedCategory;
    @track showCategory = false;
    @track typeAsParameter='';
    @track subjectDepartment
    @track suppliedEmail
    @track suppliedname;
    @track suppliedphone
    @track modelName
     
    objectInfo;
    allPicklists = {};
    showAddButton = false;


    mobile='';
    VRN='';
    VIN='';
    vehicleList=[];

    vehicleOptions = [];
    selectedVehicle = '';

    recentCases=[];
    recentJobCards=[];
    
    department='';
    accountOptions=[];

    //@track typeAsParameter;

    //@track filter; //added By Aniket on 29/04/2025

    selectedAccount='';
    caseType='';

    caseOrigin = '';//added by Aniket On 22/04/2025
    showSpinner=false;//added by Aniket on 22/04/2025

    currentOwnerId='';

    handleMobileChange(event){
         this.mobile=event.target.value;
         console.log('Mobile ==>',this.mobile);
    }
    handleVRNChange(event){
          this.VRN=event.target.value;
          console.log('VRN==>',this.VRN);
    }
    handleVINChange(event){
          this.VIN=event.target.value;
          console.log('VIN==>',this.VIN);
    }
    handleSearchVehicle() {
        console.log('Searching for vehicles with mobile:', this.mobile);
        
        // if (!this.mobile || this.mobile.trim() === '') {
        //     console.error('Mobile number is empty or undefined.');
        //     return;
        // }
    
        getAllVehicle({ mobile: this.mobile,VIN:this.VIN,VRN : this.VRN})
            .then((result) => {
                console.log('Raw Vehicle Data from Apex:', result);
                this.vehicleList = result;
               // this.currentOwnerId = result[0].Account__c;
                //console.log('Extracted Current Owner Id:', this.currentOwnerId);
                this.vehicleOptions = result.map(vehicle => ({
                    label: `${vehicle.Name} (${vehicle.VehicleRegistrationNumber}) (${vehicle.VehicleIdentificationNumber})`,
                    value: vehicle.Id
                }));
                console.log('Formatted Vehicle Options:', this.vehicleOptions);
            })
            .catch((error) => {
                console.error('Error Fetching Vehicle Details:', JSON.stringify(error));
            });
    }

    handleVehicleChange(event) {
        debugger;
        this.selectedVehicle = event.target.value;

      
    const selectedVehicleRecord = this.vehicleList.find(vehicle => vehicle.Id === this.selectedVehicle);
    console.log('selectedVehicleRecord==>',selectedVehicleRecord);
    
    if (selectedVehicleRecord) {
        this.currentOwnerId = selectedVehicleRecord.CurrentOwnerId;
        this.suppliedEmail = selectedVehicleRecord.CurrentOwner.Email__c;
        this.suppliedname = selectedVehicleRecord.CurrentOwner.Name;
        this.suppliedphone = selectedVehicleRecord.CurrentOwner.Phone;
        this.modelName = selectedVehicleRecord.ModelName != null ? selectedVehicleRecord.ModelName : 'Model Name Is Blank';
        this.VIN = selectedVehicleRecord.VehicleIdentificationNumber;//added now
        this.VRN=selectedVehicleRecord.VehicleRegistrationNumber;//added now
        console.log('Extracted Current Owner Id:', this.currentOwnerId);
        console.log('Supplied Name==>',this.suppliedname);
    } else {
        console.error('Selected vehicle not found in vehicle list.');
    }


        this.fetchRecentCases(this.selectedVehicle);
        this.fetchRecentJobCards(this.selectedVehicle);
    }
    
    fetchRecentCases(vehicleId) {
        debugger;
        getRecentCases({ vehicleId })
            .then((result) => {
                this.recentCases = result;
                console.log('case list==>',result);
            })
            .catch((error) => {
                console.error('Error fetching recent cases:', error);
            });
    }
    fetchRecentJobCards(vehicleId) {
        debugger;
        getJobCardList({ vehicleId })
            .then((result) => {
                this.recentJobCards = result;
                console.log('Job Cards list==>',result);
            })
            .catch((error) => {
                console.error('Error fetching recent cases:', error);
            });
    }
    
    get departMentoptions(){
        return [
            {label : 'Sales' , value:'Sales'},
            {label :'Service' , value:'Service'},
            {label :'Merchandise' , value:'Merchandise'},
            {label :'Accessories' , value:'Accessories'},
        ]
    }
    categoryOptionsMap = {
        'Sales': [
            { label: 'Accessories', value: 'Accessories' },
            { label: 'Brakes', value: 'Brakes' },
            { label: 'Bootlamp', value: 'Bootlamp' }
        ],
        'Service': [
            { label: 'Centre Stand', value: 'Centre Stand' },
            { label: 'Charger', value: 'Charger' },
            { label: 'Crash Guard', value: 'Crash Guard' }
        ]
    };

    handleDepartmentChange(event) {
        debugger;
        this.department = event.detail.value;
        this.subjectDepartment = this.department;
        console.log('Department ==>', this.department);
        if(this.department != null && this.department != undefined){
            this.categoryOptions = this.getFilteredOptions(
                this.allPicklists[Case_Category__c.fieldApiName],
                this.department);
         
             this.showAddButton = true;
 
         // Determine typeAsParameter based on department selection
         if (this.department === 'Sales') {
             this.typeAsParameter = 'Dealer';
            
         } else if (this.department === 'Service') {
             this.typeAsParameter = 'Service Center';
             
         } else {
             this.typeAsParameter = null;
             
         }
         console.log('typeAsParameter ==>', this.typeAsParameter);

         
         

         // Call Apex method to fetch Account List
        //  getAccountList({ typeOfAccount: this.typeAsParameter })
        //      .then((result) => {
        //          this.accountOptions = result.map(acc => ({
        //              label: acc.Name,
        //              value: acc.Id
        //          }));
        //          console.log('Account options ==>', this.accountOptions);
        //      })
        //      .catch(error => {
        //          console.log('Error=>', error);
        //      });
        
        // if (this.typeAsParameter) {
        //     this.filter = JSON.stringify({
        //         conditions: [
        //             {
        //                 field: 'Type',
        //                 operator: 'eq',
        //                 value: this.typeAsParameter
        //             }
        //         ],
        //         logic: 'and'
        //     });
        // } else {
        //     this.filter = null;
        // }
 
         // Update category options dynamically
        // this.updateCategoryOptions();
     }
 
        }
        
    // updateCategoryOptions() {
    //     if (this.department in this.categoryOptionsMap) {
    //         this.categoryOptions = this.categoryOptionsMap[this.department];
    //         this.showCategory = true;  // Show the category picklist
    //     } else {
    //         this.categoryOptions = [];
    //         this.showCategory = false; // Hide the category picklist if no values exist
    //     }

    //     // Reset selected category when department changes
    //     this.selectedCategory = null;
    //     console.log('Updated Category Options ==>', this.categoryOptions);
    // }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        console.log('Selected Category ==>', this.selectedCategory);
    }
    handleAccountChange(event){
    debugger;
    this.selectedAccount=event.detail.recordId;
    console.log('AccountId==>',this.selectedAccount);
    if (this.selectedAccount) {
        const dealerCombo = this.template.querySelector('[data-id="assignDealer"]');
        dealerCombo.setCustomValidity('');
        dealerCombo.reportValidity();
        //hasError = true;
    }
    }
    // get filter(){
    //     return `Type = '${this.typeAsParameter}'`;
    // }
    get filter() {
    return {
        criteria: [
            {
                fieldPath: 'Type',
                operator: 'eq',
                value: 'Dealer',
            },
            {
                fieldPath: 'Type',
                operator: 'eq',
                value: 'Service Center',
            }
        ],
        filterLogic: '1 OR 2'
    };
}
// get filter() {
//     if (!this.typeAsParameter) return null;

//     return {
//         criteria: [
//             {
//                 fieldPath: 'Type',
//                 operator: 'eq',
//                 value: this.typeAsParameter,
//             }
//         ],
//         filterLogic: '1'
//     };
// }


//     get filter() {
//         debugger;
//     if (!this.typeAsParameter) return null;

//     console.log('typeAsParameter ==>', this.typeAsParameter);
//     return {
//         conditions: [
//             {
//                 field: 'Type',
//                 operator: 'eq',
//                 value: this.typeAsParameter
//             }
//         ],
//         logic: 'and'
//     };
// }


//     get filter() {
//         debugger;
//     const filterValue = this.typeAsParameter ? `Type = '${this.typeAsParameter}'` : '';
//     console.log('Computed filter ==>', filterValue);
//     return filterValue;
// }

    get caseTypeoptions(){
        return[
            {label : 'General Query', value : 'General Query'},
            {label : 'Complaint', value : 'Complaint'},
            {label : 'Urgent Complaint', value : 'Urgent Complaint'},
            {label : 'Service Request', value : 'Service Request'},
            {label : 'PSFU Concerns', value : 'PSFU Concerns'}
        ]
    }
    get caseOriginoptions(){
        return[
            {label :'Email' ,value:'Email'},
            {label :'Chat' ,value:'Chat'},
            {label :'Phone' ,value:'Phone'},
            {label :'Social' ,value:'Social'}

        ]
    }

    handleCaseTypeChange(event){
        debugger;
        this.caseType = event.target.value;
        console.log('Case type ==>',this.caseType);
        //added by Aniket on 22/04/2025
        if (this.caseType) {
            const caseTypeCombo1 = this.template.querySelector('[data-id="caseType"]');
            caseTypeCombo1.setCustomValidity('');
            caseTypeCombo1.reportValidity();
        }
        // this.customerConcerns = [...this.customerConcerns].map(concern => {
        //     return { ...concern, selectedType: this.caseType };
        // });

    }
    //added by Aniket on 22/04/2025
    handleCaseOriginChange(event){
        debugger;
        this.caseOrigin = event.detail.value;
        console.log('Case Origin ==>',this.caseOrigin);
        //added by Aniket on 22/04/2025
        if (this.caseOrigin) {
            const caseOriginCombo1 = this.template.querySelector('[data-id="caseOrigin"]');
            caseOriginCombo1.setCustomValidity('');
            caseOriginCombo1.reportValidity();
        }
    }
    
    @wire(getObjectInfo, { objectApiName: Customer_Concern__c })
    objectInfoHandler({ data, error }) {
        if (data) {
            this.objectInfo = data;
        } else if (error) {
            console.error('Error fetching object info:', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: Type__c })
    wiredTypePicklist({ data, error }) {
        if (data) {
            this.typeOptions = this.formatPicklistOptions(data);
            this.allPicklists[Type__c.fieldApiName] = data;
        } else if (error) {
            console.error('Error loading Type picklist values:', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: Case_Category__c })
    wiredCategoryPicklist({ data, error }) {
        if (data) {
            this.allPicklists[Case_Category__c.fieldApiName] = data;
        } else if (error) {
            console.error('Error loading Category picklist values:', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: Concerns__c })
    wiredConcernPicklist({ data, error }) {
        if (data) {
            this.allPicklists[Concerns__c.fieldApiName] = data;
        } else if (error) {
            console.error('Error loading Concerns picklist values:', JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.defaultRecordTypeId', fieldApiName: Subconcerns__c })
    wiredSubconcernPicklist({ data, error }) {
        if (data) {
            this.allPicklists[Subconcerns__c.fieldApiName] = data;
        } else if (error) {
            console.error('Error loading Subconcern picklist values:', JSON.stringify(error));
        }
    }

    formatPicklistOptions(picklistData) {
        return picklistData.values.map(item => ({ label: item.label, value: item.value }));
    }

    
    addRow() {
         if (this.customerConcerns.length >= 5) {
        this.showToast('Oops', 'You Can add upto 5 concerns', 'warning');
        return;
    }

        this.customerConcerns = [
            ...this.customerConcerns,
            {
                id: Date.now(),
                selectedType: '',
                selectedCategory: '',
                selectedConcern: '',
                selectedSubconcern: '',
                enteredVOC: '',
                typeOptions: this.typeOptions,
                categoryOptions: this.categoryOptions,
                concernOptions: [],
                subconcernOptions: [],
                isCategoryDisabled: true,
                isConcernDisabled: true,
                isSubconcernDisabled: true
            }
        ];
    }

    
    handleDeleteRow(event) {
        const rowId = parseInt(event.currentTarget.dataset.id);
        this.customerConcerns = this.customerConcerns.filter(row => row.id !== rowId);
    }

    
handleFieldChange(event) {
    debugger;
    const rowId = parseInt(event.target.dataset.id);
    const field = event.target.dataset.field;
    const value = event.target.value;

    this.customerConcerns = this.customerConcerns.map(row => {
        if (row.id === rowId) {
            let updatedRow = { ...row, [field]: value };

            if (field === 'selectedType') {
                // updatedRow.selectedCategory = '';
                // updatedRow.selectedConcern = '';
                // updatedRow.selectedSubconcern = '';
                // updatedRow.categoryOptions = this.getFilteredOptions(
                //     this.allPicklists[Case_Category__c.fieldApiName],
                //     value
                // );
                updatedRow.isCategoryDisabled = updatedRow.categoryOptions.length === 0;
                updatedRow.isConcernDisabled = true;
                updatedRow.isSubconcernDisabled = true;
            } else if (field === 'selectedCategory') {
                updatedRow.selectedConcern = '';
                updatedRow.selectedSubconcern = '';
                updatedRow.concernOptions = this.getFilteredOptions(
                    this.allPicklists[Concerns__c.fieldApiName],
                    value
                );
                updatedRow.isConcernDisabled = updatedRow.concernOptions.length === 0;
                updatedRow.isSubconcernDisabled = true;
            } else if (field === 'selectedConcern') {
                updatedRow.selectedSubconcern = '';
                updatedRow.subconcernOptions = this.getFilteredOptions(
                    this.allPicklists[Subconcerns__c.fieldApiName],
                    value
                );
                updatedRow.isSubconcernDisabled = updatedRow.subconcernOptions.length === 0;
            }

            return updatedRow;
        }
        return row;
    });
}


getFilteredOptions(picklistField, selectedValue) {
    if (!selectedValue || !picklistField || !picklistField.controllerValues) {
        return [];
    }

    const controllerValues = picklistField.controllerValues || {};

    return picklistField.values
        .filter(item => 
            item.validFor && 
            controllerValues[selectedValue] !== undefined &&
            item.validFor.includes(controllerValues[selectedValue])
        )
        .map(item => ({ label: item.label, value: item.value }));
}

handleRemoveAll() {
    if (this.customerConcerns.length === 0) {
        this.showToast('Info', 'No records to clear.', 'info');
        return;
    }

    this.customerConcerns = this.customerConcerns.map(concern => ({
        ...concern,
        selectedType: '',
        selectedCategory: '',
        selectedConcern: '',
        selectedSubconcern: '',
        enteredVOC: '',
        categoryOptions: [],
        concernOptions: [],
        subconcernOptions: [],
        isCategoryDisabled: true,
        isConcernDisabled: true,
        isSubconcernDisabled: true
    }));

    this.showToast('Success', 'All data has been cleared.', 'success');
}




    
    // async handleSubmit() {
    //     debugger;
    //     if (this.customerConcerns.length === 0) {
    //         this.showToast('Error', 'No records to submit.', 'error');
    //         return;
    //     }

    //     const caseFields = { Case_Type__c: this.caseType, Status: 'open' ,AccountId : this.selectedAccount,Vehicle__c:this.selectedVehicle};

    //     const caseRecord = await createRecord({ apiName: Case.objectApiName, fields: caseFields });

    //         const caseId = caseRecord.id;
    //         console.log('Created Case ID:', caseId);

    //     const recordPromises = this.customerConcerns.map(concern => {
    //         const fields = {
    //             [Type__c.fieldApiName]: concern.selectedType,
    //             [Case_Category__c.fieldApiName]: concern.selectedCategory,
    //             [Concerns__c.fieldApiName]: concern.selectedConcern,
    //             [Subconcerns__c.fieldApiName]: concern.selectedSubconcern,
    //             [VOC__c.fieldApiName]: concern.enteredVOC,
    //             [Case__c.fieldApiName]: caseId
    //         };

    //         return createRecord({ apiName: Customer_Concern__c.objectApiName, fields });
    //     });

    //     try {
    //         await Promise.all(recordPromises);
    //         this.showToast('Success', 'Case and Customer Concerns Created Successfully', 'success');
    //         this.customerConcerns = [];
    //     } catch (error) {
    //         console.error('Error creating records:', error);
    //         this.showToast('Error', 'Error creating Customer Concerns', 'error');
    //     }
    // }
    async handleSubmit() {
        debugger;

        this.showSpinner = true;//added by Aniket on 22/04/2025
        await Promise.resolve();//added by Aniket on 22/04/2025

        this.template.querySelectorAll('lightning-combobox').forEach(cb => {
            cb.setCustomValidity('');
            cb.reportValidity();
        });
    
        let hasError = false;
    
        if (!this.caseType) {
            const caseTypeCombo = this.template.querySelector('[data-id="caseType"]');
            caseTypeCombo.setCustomValidity('Case Type cannot be empty');
            caseTypeCombo.reportValidity();
            hasError = true;
        }
        //added by Aniket on 22/04/2025
        if(!this.caseOrigin){
            const caseOriginCombo = this.template.querySelector('[data-id="caseOrigin"]');
            caseOriginCombo.setCustomValidity('Case Origin cannot be empty');
            caseOriginCombo.reportValidity();
            hasError = true;

        }
    
       /* if (!this.selectedAccount) {
            const dealerCombo = this.template.querySelector('[data-id="assignDealer"]');
            dealerCombo.setCustomValidity('You must assign the case to a dealer');
            dealerCombo.reportValidity();
            hasError = true;
        } */
    
        if (hasError) {
            this.showSpinner = false;
            return;

        }

        if (this.customerConcerns.length === 0) {
            this.showToast('Error', 'Fill Atleast One Additional Detail', 'error');
            this.showSpinner = false;
            return;
        }
    
        try {
            
            const caseFields = {
                Case_Type__c: this.caseType,
                Status: 'Open',
                Assign_to_Dealer__c: this.selectedAccount,
                Vehicle__c: this.selectedVehicle,
                AccountId:this.currentOwnerId,
                Origin:this.caseOrigin,
                Subject : this.subjectDepartment,//hardcoded for now
                Description: 'Customer Concerns',
                SuppliedEmail :this.suppliedEmail,
                SuppliedName:this.suppliedname,
                SuppliedPhone:this.suppliedphone,
                Model_Name__c : this.modelName
                
                 
            };
    
            const caseRecord = await createRecord({ apiName: Case.objectApiName, fields: caseFields });
            const caseId = caseRecord.id;

           
            //const caseNumberNow = caseRecord.CaseNumber;

            
            //const fullCase = await getRecord({ recordId: caseId, fields: [CASE_NUMBER_FIELD] });
           // const caseNumber = fullCase.fields.CaseNumber.value;
            console.log('Created Case ID:', caseId);
            //console.log('Created Case Number:', caseNumberNow);
    
            
            const recordPromises = this.customerConcerns.map(concern => {
                const fields = {
                    [Type__c.fieldApiName]: concern.selectedType,
                    [Case_Category__c.fieldApiName]: concern.selectedCategory,
                    [Concerns__c.fieldApiName]: concern.selectedConcern,
                    [Subconcerns__c.fieldApiName]: concern.selectedSubconcern,
                    [VOC__c.fieldApiName]: concern.enteredVOC,
                    [Case_Category_Update__c.fieldApiName]:concern.selectedCategory,//added by Aniket on 28/04/2025
                    Case__c: caseId  
                };
    
                return createRecord({ apiName: Customer_Concern__c.objectApiName, fields });
            });
    
            await Promise.all(recordPromises);
            this.showToast('Success', `Case and Customer Concerns Created Successfully with ${caseId}`, 'success');

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: caseId,
                    objectApiName: 'Case',
                    actionName: 'view'
                }
            });//added by Aniket on 28/04/2025
            //window.location.reload();
            this.customerConcerns = [];
            //added by Aniket on 22/04/2024
            setTimeout(() => {
                this.showSpinner = false;
                window.location.reload();
            }, 2000); 
    
    
        } catch (error) {
            console.error('Error creating records:', JSON.stringify(error));
            console.error('Error creating records:', error);
            this.showToast('Error', 'Error creating Case and Customer Concerns', 'error');
            this.showSpinner = false;//added by Aniket on 22/04/2025
            //window.location.reload();
        }
    }
    

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}