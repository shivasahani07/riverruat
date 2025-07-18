import { LightningElement, track, wire } from 'lwc';
import getLogedInUserRelatedLocationPOLI from '@salesforce/apex/OrderController.getLogedInUserRelatedLocationPOLI';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import createOrderProductLineItems from '@salesforce/apex/OrderController.createOrderProductLineItems';
import createOrderRecord from '@salesforce/apex/OrderController.createOrderRecord';
import createAccount from '@salesforce/apex/OrderController.createAccount';
import getAllVehicle from '@salesforce/apex/VehicleController.getAllVehicle';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';


import { CloseActionScreenEvent } from 'lightning/actions';

export default class OrderProductLwc extends NavigationMixin(LightningElement) {

    //@api recordId;
    @track addprd = false;
    @track requestLineItems = [];
    @track selectedItems = [];
    //@track updatedValues = new Map();
    @track filteredRequestLineItems = [];
    @track updatedValues = new Map();
    @track selectAllChecked = false;
    showSpinner = false;
    //currentUserId;
    PoCreatedRecordId;
    recordIdfromURL = '';
    
    buttonVisible = false;
    @track additonalDiscount;
    OrderTotal = 0;
    FinalPayableAmount = 0;
    additonalDiscount = 0;

    @track showAccountForm = false;
    @track accountName = '';
    @track accountPhone = '';
    @track accountEmail = '';
    @track accountType = '';
    @track typeOptions = [];


    //vehicle 
    @track vehicles = [];
    @track error;
    @track accounts = [];

    @track mobile = '';
    @track vin = '';
    @track vrn = '';
    @track selectedVehicleId = null;
    @track ShowVehicleSearch = true;

    // Pagination state
    @track currentPage = 1;
    @track recordsPerPage = 5;
    @track totalPages = 1;
    @track currentPageData = [];

    //veicle Pagination
    @track paginatedVehicles = [];
    @track currentPageVehicles = 1;
    @track VehirecordsPerPage = 5;
    @track totalPagesVehicles = 1;
    @track currentPageDataVehicles = [];
    @track ShowAccButton = false;

    @track showSpinner = false;
    @track relatedAccount;
    @track discountAmount

    @track selectedAccount='';
    @track isFromAccount=false;
    @track ewPresent;
    @track onlyShowVehicle = false;
    connectedCallback() {
        debugger;

        if (this.recordId == undefined) {
            let params = location.search
            const urlParams = new URLSearchParams(params);
            this.recordIdfromURL = urlParams.get("recordId");
        }
        this.recordId = this.recordId;
        console.log(this.recordId);
        this.callApexMethod();
    }

    closeModal() {
        debugger;
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
        //this.close('close');
    }

    callApexMethod() {
        debugger;
        this.showSpinner = true;
        const spinnerDelay = 1000;
        const startTime = new Date().getTime();
        getLogedInUserRelatedLocationPOLI()
            .then((data) => {
                if (data) {
                    this.requestLineItems = data.map((res) => ({
                        Id: res.Id,
                        ProductName: res.Name,
                        ProductCode: res.ProductCode,
                        unitPirce: res.PricebookEntries[0].UnitPrice,
                        tax: res.PricebookEntries[0].IGST__c != null ? res.PricebookEntries[0].IGST__c : 0,
                       discount: res.Merchandise_discount_price__c != null ? res.Merchandise_discount_price__c : 0,
                        Type: res.Type__c,
                        AllocatedQuantity: 1,
                        totalBeforediscount: 0,
                        TotalAmountAfterDiscount: 0,
                        OrderTotal: 0,
                        FinalPayableAmount: 0,
                        selected: false,
                        totalPrice: 0,
                        isChargesDisabled: true,
                    }));
                    this.filteredRequestLineItems = [];
                    this.error = undefined;
                } else {
                    this.filteredRequestLineItems = [];
                    this.requestLineItems = [];
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error fetching product request items:', error);
            })
            .finally(() => {

                const elapsedTime = new Date().getTime() - startTime;
                const remainingTime = Math.max(0, spinnerDelay - elapsedTime);
                setTimeout(() => {
                    this.showSpinner = false;
                }, remainingTime);
            });
    }

    handleSearchInput(event) {
        debugger;
        const searchTerm = event.target.value.toLowerCase().trim();
        if (searchTerm) {
            this.filteredRequestLineItems = this.requestLineItems.filter(item => (
                item.ProductName.toLowerCase().startsWith(searchTerm) || item.ProductCode.toLowerCase().startsWith(searchTerm) || item.Type.toLowerCase().startsWith(searchTerm))
            );
            this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
            this.currentPage = 1;
            this.updatePageData();
        } else if (!searchTerm) {
            this.filteredRequestLineItems = [];
            this.updatePageData();
        }
        this.selectAllChecked = this.currentPageData.every(item => item.selected);
    }
 



    handleDelete(event) {
        debugger;
        const itemId = event.target.dataset.id;
        this.currentPageData = this.currentPageData.filter(item => item.Id !== itemId);
        this.requestLineItems = this.requestLineItems.filter(item => item.Id !== itemId);
    }

    // handleDeleteSelectedItem(event) {
    //     debugger;
    //     const itemId = event.target.dataset.id;
    //     const deletedItem = this.selectedItems.find(item => item.Id === itemId);
        
    //     if (deletedItem) {
    //         this.selectedItems = this.selectedItems.filter(item => item.Id !== itemId);
    //         this.selectedItems = this.selectedItems.map((item, index) => ({
    //             ...item,
    //             index: index + 1
    //         }));
    
    //         const alreadyExists = this.filteredRequestLineItems.some(item => item.Id === itemId);
    //         if (!alreadyExists) {
    //             this.filteredRequestLineItems.push({
    //                 ...deletedItem,
    //                 selected: false,
    //                 isChargesDisabled: true
    //             });
    
    //             this.filteredRequestLineItems.sort((a, b) => a.index - b.index);
    //         }
    
    //         this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
    //     }
    
    //     this.updatePageData();
    //     this.selectAllChecked = this.currentPageData.every(item => item.selected);
    //     this.buttonVisible = this.selectedItems.length > 0;
    // }
    // handleDeleteSelectedItem(event) {
    //     debugger;
    //     const itemId = event.target.dataset.id;
    
    //     // Ensure correct type comparison
    //     const deletedItem = this.selectedItems.find(item => item.Id == itemId); // use loose equality
    
    //     if (deletedItem) {
    //         this.selectedItems = this.selectedItems.filter(item => item.Id != itemId); // use loose equality
    
    //         this.selectedItems = this.selectedItems.map((item, index) => ({
    //             ...item,
    //             index: index + 1
    //         }));
    
    //         const alreadyExists = this.filteredRequestLineItems.some(item => item.Id == itemId); // use loose equality
    
    //         if (!alreadyExists) {
    //             this.filteredRequestLineItems.push({
    //                 ...deletedItem,
    //                 selected: false,
    //                 isChargesDisabled: true
    //             });
    
    //             this.filteredRequestLineItems.sort((a, b) => a.index - b.index);
    //         }
    
    //         this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
    //     }
    
    //     this.updatePageData();
    //     this.selectAllChecked = this.currentPageData.every(item => item.selected);
    //     this.buttonVisible = this.selectedItems.length > 0;
    // }

    handleDeleteSelectedItem(event) {
        debugger;
        const itemId = event.target.dataset.id;
    
        const deletedItem = this.selectedItems.find(item => item.Id == itemId);
    
        if (deletedItem) {
            this.selectedItems = this.selectedItems.filter(item => item.Id != itemId);
    
            
            const hasEW = this.selectedItems.some(item => item.ProductCode && item.ProductCode.startsWith('RV-EW'));
            this.ewPresent = hasEW;
    
            this.selectedItems = this.selectedItems.map((item, index) => ({
                ...item,
                index: index + 1
            }));
    
            const alreadyExists = this.filteredRequestLineItems.some(item => item.Id == itemId);
    
            if (!alreadyExists) {
                this.filteredRequestLineItems.push({
                    ...deletedItem,
                    selected: false,
                    isChargesDisabled: true
                });
                
                this.filteredRequestLineItems.sort((a, b) => a.index - b.index);
            }
    
            this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
        }
        this.ewPresent = false;//added by Aniket on 12/05/2025
        this.updatePageData();
        this.selectAllChecked = this.currentPageData.every(item => item.selected);
        this.buttonVisible = this.selectedItems.length > 0;
    }
    
    


    handleQuantityChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const updatedQuantity = parseFloat(event.target.value.trim()) || 0;
        let unitPrice = 0, tax = 0, discount = 0;

        if (this.selectedItems) {
            const selectedItem = this.selectedItems.find(item => item.Id === itemId);
            if (selectedItem) {
                unitPrice = selectedItem.unitPirce;
                tax = selectedItem.tax;
                discount = selectedItem.discount;
                
            }
        }

        this.selectedItems = this.selectedItems.map(item => {
            if (item.Id === itemId) {

                let totalPrice = (updatedQuantity === 0) ? 0 : (updatedQuantity ? updatedQuantity * unitPrice : unitPrice) - discount;
                let totalBeforediscount = totalPrice ? totalPrice + (totalPrice * (tax / 100)) : 0;
                let TotalAmountAfterDiscount = totalBeforediscount ? totalBeforediscount : 0;

                return {
                    ...item,
                    AllocatedQuantity: updatedQuantity,
                    totalPrice,
                    totalBeforediscount,
                    TotalAmountAfterDiscount
                };
            }
            return item;
        });

        this.filteredRequestLineItems = [...this.selectedItems];
        this.calculateFinalPayableAmount();
        this.handleAddtionalQty();

    }

   handleAddtionalQty(event) {
    const itemId = event.target.dataset.id;
    const newDiscount = parseFloat(event.target.value) || 0;

    this.selectedItems = this.selectedItems.map(item => {
        if (item.Id === itemId) {
            return {
                ...item,
                additionalDiscount: newDiscount
            };
        }
        return item;
    });

    this.filteredRequestLineItems = [...this.selectedItems];
    this.calculateFinalPayableAmount();
}

   calculateFinalPayableAmount() {
    let totalOrderAmount = 0;
    let totalDiscountAmount = 0;

    this.selectedItems = this.selectedItems.map(item => {
        const itemDiscount = item.additionalDiscount || 0;
        const discountOnItem = (itemDiscount / 100) * item.totalBeforediscount;
        const TotalAmountAfterDiscount = item.totalBeforediscount - discountOnItem;

        totalOrderAmount += TotalAmountAfterDiscount;
        totalDiscountAmount += discountOnItem;

        return {
            ...item,
            TotalAmountAfterDiscount
        };
    });

    this.filteredRequestLineItems = [...this.selectedItems];
    this.OrderTotal = totalOrderAmount;
    this.discountAmount = totalDiscountAmount;
    this.FinalPayableAmount = totalOrderAmount;
}




    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
    
        if (isChecked) {
            const updatedSelectedItems = [];
            const updatedPageData = [];
    
            // Remove existing selected items from current page to avoid duplicates
            const currentPageIds = this.currentPageData.map(item => item.Id);
            this.selectedItems = this.selectedItems.filter(item => !currentPageIds.includes(item.Id));
    
            for (const item of this.currentPageData) {
                const isRestricted =
                    this.isFromAccount &&
                    (item.Type === 'Road side assistance' || (item.ProductCode && item.ProductCode.startsWith('RV-EW')));
    
                if (isRestricted) {
                    this.showToast('Warning', `Product ${item.ProductName} cannot be selected (RSA or EW)`, 'warning');
                    updatedPageData.push({ ...item, selected: false, isChargesDisabled: true });
                    continue;
                }
    
                const isExtendedWarranty = item.ProductCode && item.ProductCode.startsWith('RV-EW');
                const alreadyAddedEW = [...this.selectedItems, ...updatedSelectedItems].find(i =>
                    i.ProductCode && i.ProductCode.startsWith('RV-EW')
                );
    
                if (isExtendedWarranty && alreadyAddedEW) {
                    this.showToast('Warning', `Only one Extended Warranty can be selected. Skipping ${item.ProductName}`, 'warning');
                    updatedPageData.push({ ...item, selected: false, isChargesDisabled: true });
                    continue;
                }
    
                const updatedItem = {
                    ...item,
                    selected: true,
                    isChargesDisabled: false
                };
    
                updatedSelectedItems.push({ ...updatedItem, index: this.selectedItems.length + updatedSelectedItems.length + 1 });
                updatedPageData.push(updatedItem);
            }
    
            this.selectedItems = [...this.selectedItems, ...updatedSelectedItems];
            this.currentPageData = updatedPageData;
        } else {
            // Deselect all items on current page
            this.currentPageData = this.currentPageData.map(item => ({
                ...item,
                selected: false,
                isChargesDisabled: true
            }));
    
            const currentPageIds = this.currentPageData.map(item => item.Id);
            this.selectedItems = this.selectedItems.filter(item => !currentPageIds.includes(item.Id));
        }
    
        this.buttonVisible = this.selectedItems.length > 0;
    
        // If any EW product remains in selected items
        this.ewPresent = this.selectedItems.some(item => item.ProductCode && item.ProductCode.startsWith('RV-EW'));
    }
    
    handleCheckboxChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        
        
        const selectedProduct = this.currentPageData.find(item => item.Id === itemId);

        
        if (this.isFromAccount && isChecked) {
            const isRestricted =
                selectedProduct.Type === 'Road side assistance' ||
                selectedProduct.ProductCode.startsWith('RV-EW');
    
            if (isRestricted) {
                this.showToast('Warning', 'You cannot select RSA or Extended Warranty Products', 'warning');
                event.target.checked = false;
                return;
            }
        }

        // if(isChecked){
        //     const alreadyAddedEW = this.selectedItems.find(item => item.ProductCode.startsWith(RV-EW));
        //     if(alreadyAddedEW){
        //         this.showToast('Warning', 'You cannot select more than one Extended Warranty', 'warning');
        //         event.target.checked = false;
        //         return;
        //     }
        // }
        if (isChecked) {
            const isExtendedWarranty = selectedProduct.ProductCode && selectedProduct.ProductCode.startsWith('RV-EW');
            if (isExtendedWarranty) {
                const alreadyAddedEW = this.selectedItems.find(item => item.ProductCode && item.ProductCode.startsWith('RV-EW'));
                if (alreadyAddedEW) {
                    this.ewPresent=true;
                    this.showToast('Warning', 'You cannot select more than one Extended Warranty', 'warning');
                    event.target.checked = false;
                    this.currentPageData = this.currentPageData.map(item => {
                        if (item.Id === itemId) {
                            return { ...item, selected: false };
                        }
                        return item;
                    });
                
                    return;
                    // event.target.checked = false;
                    // return;
                }
            }
        }
        this.ewPresent=false;//added by Aniket on 12/05/2025
        
        this.currentPageData = this.currentPageData.map(item => {
            if (item.Id === itemId) {
                const updatedItem = { ...item, selected: isChecked };
                if (isChecked) {
                    this.selectedItems = [
                        ...this.selectedItems,
                        { ...updatedItem, index: this.selectedItems.length + 1 }
                    ];
                    this.buttonVisible = true;
                    const quantityChangeEvent = {
                        target: {
                            dataset: { id: itemId },
                            value: '1'
                        }
                    };
                    this.handleQuantityChange(quantityChangeEvent);
                } else {
                    this.selectedItems = this.selectedItems.filter(i => i.Id !== itemId);
            
                    
                    const hasEW = this.selectedItems.some(item => item.ProductCode && item.ProductCode.startsWith('RV-EW'));
                    this.ewPresent = hasEW;
                }
                return updatedItem;
            }
            return item;
        });
    
        
        if (isChecked) {
            this.currentPageData = this.currentPageData.filter(item => item.Id !== itemId);
        }
    
        if (this.selectedItems.length > 0) {
            this.buttonVisible = true;
        }
        this.selectAllChecked = this.currentPageData.every(item => item.selected);
    }
    
    

    


    handleUpdateProcess() {
        debugger;
        const invalidItems = this.selectedItems.filter(item => {
            return isNaN(item.AllocatedQuantity) || item.AllocatedQuantity <= 0 || item.AllocatedQuantity === '' || item.AllocatedQuantity === null;
        });
        
        if (invalidItems.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please ensure all quantities are entered and greater than 0.',
                    variant: 'error'
                })
            );
            this.showSpinner= false;
            return;
        }

        const updatedItems = this.selectedItems.map(item => ({
            Id: item.Id,
            QuantityRequested: parseFloat(item.AllocatedQuantity),
            Product2Id: item.Id,
            ParentId: this.PoCreatedRecordId,
            DiscountPercent: item.additionalDiscount || 0
        }));
        console.log('UpdatedItemss:::' + JSON.stringify(updatedItems));

        createOrderProductLineItems({ jsonData: JSON.stringify(updatedItems) })
            .then(result => {
                console.log('result =>' + result);
                console.log(
                    'UpdatedItemss:::' + JSON.stringify(result))
                if (result === 'SUCCESS') {

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Records Created Successfully! with Id ${this.PoCreatedRecordId}`,
                            variant: 'success'
                        })
                    );
                    // this.closeModal();
                    // this.dispatchEvent(new CloseActionScreenEvent());
                    this.updatedValues.clear();
                    this.closeModal();
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: `/autocloudSite/s/order/${this.PoCreatedRecordId}/detail`
                        }
                    });
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error Creating records: ' + result,
                            variant: 'error'
                        })
                    );
                    this.closeModal();
                }
            })
            .catch(error => {
                console.error('Error: ', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error Creating records: ' + error.body.message,
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    methodToCreateOrdersRecords() {
        debugger;
        // const ewPresent = this.selectedItems.some(
        //     product => product.ProductCode && product.ProductCode.startsWith('RV-EW')
        // );
        
        const ewProduct = this.selectedItems.find(
        product => product.ProductCode && product.ProductCode.startsWith('RV-EW')
    );
 
    const ewPresent = !!ewProduct; // true if ewProduct is found
    const ewProductCode = ewProduct ? ewProduct.ProductCode : null;

        const rsaPresent = this.selectedItems.some(
            product => product.Type == 'Road side assistance'
        );
        
        this.showSpinner = true;
        createOrderRecord({ shipmentType: 'Standard', additonal: this.additonalDiscount, vehicleIdd: this.selectedVehicleId , VehicleAcc : this.relatedAccount, addDiscountAmt : this.discountAmount,selectedAccount : this.selectedAccount,ewPresent : ewPresent,rsaPresent:rsaPresent,ewProductCode:ewProductCode})
            // .then(result => {
            //     if (result) {
            //         this.PoCreatedRecordId = result;
            //         this.handleUpdateProcess();
            //     } else {
            //         this.dispatchEvent(
            //             new ShowToastEvent({
            //                 title: 'Error',
            //                 message: error.body.message,
            //                 variant: 'error'
            //             })
            //         );
            //     }
            // })

            .then(result => {
                if (result && result.startsWith('Error:')) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.replace('Error:', '').trim(),
                            variant: 'error'
                        })
                    );
                    this.showSpinner = false;
                } else if (result) {
                    this.PoCreatedRecordId = result;
                    this.handleUpdateProcess();
                }
            })
            
            .catch(error => {
                this.showSpinner = false;
                console.error('Error: ', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );

            });
    }
    
    

    handleAddProduct() {

        const modalEvent = new CustomEvent('addproduct', {
            detail: { vehicleData: this.vehicleData }
        });
        this.dispatchEvent(modalEvent);
    }

    activeDataType = 'vehicles';

    handleSearch() {
        debugger;
        this.showSpinner = true;

        // Validate inputs to ensure that at least one search criterion is entered
        if (!this.mobile && !this.vin && !this.vrn) {
            this.showSpinner = false;
            this.showToast('Error', 'Please enter at least one search criterion (Mobile, VIN, or VRN).', 'error');
            return;
        }

        const mobileRegex = /^\d{10}$/;
        if (this.mobile && !mobileRegex.test(this.mobile)) {
            this.showSpinner = false;
            this.showToast('Error', 'Please enter a valid 10-digit mobile number.', 'error');
            return;
        }


        getAllVehicle({ mobile: this.mobile, VIN: this.vin, VRN: this.vrn })
            .then((result) => {
                this.vehicles = result.vehicles || [];
                //this.accounts = result.account || [];//added by Aniket on 08/05/2025

                const accountData = result.account;
                this.accounts = Array.isArray(accountData) ? accountData : (accountData ? [accountData] : []);

                if(this.vehicles.length === 0){
                    this.onlyShowVehicle = true;
                }else{
                    this.onlyShowVehicle=false;
                }
                console.log('Accounts==>',this.accounts);
                this.paginatedVehicles = [...this.vehicles];
                this.showSpinner = false;

                // Calculate total pages
                this.totalPagesVehicles = Math.ceil(this.paginatedVehicles.length / this.VehirecordsPerPage) || 1;
                this.currentPageVehicles = 1;
                this.updatePageDataVehicles();

                console.log('Vehicles fetched:', JSON.stringify(this.vehicles));
                console.log('Accounts==>',JSON.stringify(this.accounts));
                if (!this.vehicles || this.vehicles.length === 0) {
                    this.ShowAccButton = true;
                } else {
                    this.ShowAccButton = false;
                }
            })
            .catch((error) => {
                this.error = error.body ? error.body.message : 'Unknown error occurred';
                this.showSpinner = false;
                console.error('Error fetching vehicles:', this.error);
            });
    }
    updatePageDataVehicles() {
        const start = (this.currentPageVehicles - 1) * this.recordsPerPage;
        const end = Math.min(start + this.recordsPerPage, this.paginatedVehicles.length);
        this.currentPageDataVehicles = this.paginatedVehicles.slice(start, end);
    }



    handleMobileChange(event) {
        this.mobile = event.target.value;
    }

    handleVINChange(event) {
        this.vin = event.target.value;
    }

    handleVRNChange(event) {
        debugger;
        this.vrn = event.target.value;
    }

   /* handleAddProduct(event) {
        this.selectedVehicleId = event.target.dataset.id;
        console.log('this.selectedVehicleId:', JSON.stringify(this.selectedVehicleId));
        this.addprd = true;
        this.ShowVehicleSearch = false;
    } */

        handleAddProduct(event) {
            this.selectedVehicleId = event.target.dataset.id;
            console.log('Selected Vehicle ID:', this.selectedVehicleId);
        
            // Find the selected vehicle from the list
            const selectedVehicle = this.vehicles.find(
                (vehicle) => vehicle.Id === this.selectedVehicleId
            );
        
            // Optional: debug selected vehicle
            console.log('Selected Vehicle:', selectedVehicle);
        
            // Get related account
            if (selectedVehicle && selectedVehicle.CurrentOwnerId) {
                this.relatedAccount = selectedVehicle.CurrentOwnerId;
                console.log('Related Account:', this.relatedAccount);
            } else {
                console.warn('No account found for selected vehicle.');
                this.relatedAccount = null;
            }
        
            this.addprd = true;
            this.ShowVehicleSearch = false;
        }
        handleAddProductForAccount(event){
            debugger;
            this.selectedAccount = event.target.dataset.id;
            console.log('Selected AccountId=>',this.selectedAccount);
            this.isFromAccount = true
            this.addprd = true;
            this.ShowVehicleSearch = false;
        }
        
        
        
        
        

    Handleback() {
        this.addprd = false;
        this.ShowVehicleSearch = true;
        this.buttonVisible = false;
    }

    updatePageData() {
        debugger;
        const start = (this.currentPage - 1) * this.recordsPerPage;
        const end = Math.min(start + this.recordsPerPage, this.filteredRequestLineItems.length);
        console.log('start:', start, 'end:', end);
        this.currentPageData = this.filteredRequestLineItems.slice(start, end).map((item, index) => {
            return {
                ...item,
                index: start + index + 1
            };
        });
        this.selectedItems = this.selectedItems.map((item, index) => ({
            ...item,
            index: index + 1
        }));
        console.log('start:', start, 'end:', end);
    }

    handlePreviousPage() {
        debugger;
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePageData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePageData();
        }
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    handleFirstPage() {
        debugger;
        if (this.currentPage > 1) {
            this.currentPage = 1;
            this.updatePageData();
        }
    }

    handleLastPage() {
        debugger;
        if (this.currentPage < this.totalPages) {
            this.currentPage = this.totalPages;
            this.updatePageData();
        }
    }

    get isFirstDisabled() {
        return this.currentPage === 1;
    }

    get isLastDisabled() {
        return this.currentPage === this.totalPages;
    }

    methodToCheckZeroQuntiry() {
        debugger;
        var selectedQLIList = this.filteredRequestLineItems;
        const hasZeroQuantity = selectedQLIList.some(item => item.AllocatedQuantity === 0);
        if (hasZeroQuantity) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Allocated Quantity cannot be zero.',
                    variant: 'error'
                })
            );
        }
        return hasZeroQuantity;
    }

    handlePreviousPageVehicles() {
        if (this.currentPageVehicles > 1) {
            this.currentPageVehicles--;
            this.updatePageDataVehicles();
        }
    }

    handleNextPageVehicles() {
        if (this.currentPageVehicles < this.totalPagesVehicles) {
            this.currentPageVehicles++;
            this.updatePageDataVehicles();
        }
    }

    handleFirstPageVehicles() {
        this.currentPageVehicles = 1;
        this.updatePageDataVehicles();
    }

    handleLastPageVehicles() {
        this.currentPageVehicles = this.totalPagesVehicles;
        this.updatePageDataVehicles();
    }

    // UI Binding Helpers
    get isPreviousDisabledVehicles() {
        return this.currentPageVehicles === 1;
    }

    get isNextDisabledVehicles() {
        return this.currentPageVehicles >= this.totalPagesVehicles;
    }


    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    // Fetch picklist values for Type__c
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredTypeValues({ error, data }) {
        if (data) {
            this.typeOptions = data.values;
        } else if (error) {
            console.error('Error fetching Type__c picklist values:', error);
        }
    }

    handleShowAccountForm() {
        this.showAccountForm = true;
        this.ShowAccButton = false;
    }

    handleHideAccountForm() {
        this.showAccountForm = false;
        this.ShowAccButton = true;
        this.closeModal();

    }
    handleHideAccForm() {
        this.showAccountForm = false;
        this.ShowAccButton = true;

    }

    handleInputChange(event) {
        debugger;
        this[event.target.dataset.field] = event.target.value;
    }

    handleCreateAccount() {
        debugger;

        const accountName = this.accountName ? this.accountName.trim() : '';
        const accountPhone = this.accountPhone ? this.accountPhone.trim() : '';
        const accountEmail = this.accountEmail ? this.accountEmail.trim() : '';
        const accountType = this.accountType ? this.accountType.trim() : '';

        if (!accountName || !accountPhone || !accountEmail || !accountType) {
            this.showToast('Error', 'Please Fill All Account Fields Before Clicking On Save', 'error');
            return;
        }

        const phonePattern = /^\d{10}$/;
        if (!phonePattern.test(accountPhone)) {
            this.showToast('Error', 'Phone number must be exactly 10 digits.', 'error');
            return;
        }

        // Validate email format
        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        if (!emailPattern.test(accountEmail)) {
            this.showToast('Error', 'Please enter a valid email address.', 'error');
            return;
        }

        const accountData = {
            Name: accountName,
            Phone: accountPhone,
            Email__c: accountEmail,
            Type: accountType
        };

        createAccount({ acc: accountData })
            .then(() => {
                this.showToast('Success', 'Account created successfully', 'success');
                this.handleHideAccountForm();
                this.closeModal();
            })
            .catch(error => {
                const errorMessage = error.body ? error.body.message : 'Something went wrong';
                this.showToast('Error', errorMessage, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}