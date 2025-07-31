/**
 * @author Dinesh Baddawar
 * @email dinesh.butilitarianlab@gmail.com
 * @create date 2024-12-10 13:11:20
 * @modify date 2025-01-20 19:44:47
 * @desc [Add ProductRequestLineItems Comp]
 */

import createProductRequestLineItems from '@salesforce/apex/ProductRequestLineController.createProductRequestLineItems';
import createPurchaseorder from '@salesforce/apex/ProductRequestLineController.createPurchaseorder';
import getLogedInUserRelatedLocationPOLI from '@salesforce/apex/ProductRequestLineController.getLogedInUserRelatedLocationPOLI';
//import showForeCastedData from '@salesforce/apex/ProductRequestLineController.showForeCastedData';
//import showForeCastedData from '@salesforce/apex/RecordAddProductRequestLineItemNew.getrecomendedProducts';
import showForeCastedData from '@salesforce/apex/RecordAddProductRequestLineItemNew.getAllForcastQuantity';
import userId from '@salesforce/user/Id';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track } from 'lwc';
export default class AddProductRequestLiteItem extends LightningElement {
    @api productType = 'Service';

    @api recordId;
    @track requestLineItems = [];
    @track forecastedLineItems = [];
    @track editableForecastedLineItems = [];
    @track deletedLineItems = [];
    @track selectedItems = [];
    //@track updatedValues = new Map();
    @track filteredRequestLineItems = [];
    @track updatedValues = new Map();
    @track selectAllChecked = false;
    showSpinner = false;
    showProductSpinner = false;//added by Aniket on 25/04/2025
    currentUserId;
    PoCreatedRecordId;
    recordIdfromURL = '';
    @track currentPageData = [];
    currentPage = 1;
    @track recordsPerPage = 10;
    totalPages = 0;
    buttonVisible = false;
    showForecastedData = false;
    @track showRemainingComponent=false;//added by Aniket on 25/07/2025
    @track hidebutton=true;//added by Aniket on 25/07/2025
    @track goBackToForecast=false;//added by Aniket on 25/07/2025

    connectedCallback() {
        debugger;
        this.addEventListener('filterchange', this.handleFilterChange);
        this.currentUserId = userId;
        if (this.recordId == undefined) {
            let params = location.search
            const urlParams = new URLSearchParams(params);
            this.recordIdfromURL = urlParams.get("recordId");
        }
        this.recordId = this.recordId;
        console.log(this.recordId);
        this.callApexMethod();
        // this.callApexMethod2();
        this.callApexMethod3();
    }

    closeModal() {
        const closeEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeEvent);
    }
    callApexMethod() {
        debugger;
        this.showSpinner = true;
        const spinnerDelay = 1000;
        const startTime = new Date().getTime();
        getLogedInUserRelatedLocationPOLI({ loggedInUserId: this.currentUserId, productTypeFilter: this.productType })
            .then((data) => {
                if (data) {
                    this.requestLineItems = data.map((res) => ({
                        Id: res.Id,
                        ProductName: res.Name,
                        ProductCode: res.ProductCode,
                        AllocatedQuantity: 0,
                        selected: false,
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
                // Calculate the time remaining to ensure the spinner shows for at least 3 seconds
                const elapsedTime = new Date().getTime() - startTime;
                const remainingTime = Math.max(0, spinnerDelay - elapsedTime);
                setTimeout(() => {
                    this.showSpinner = false;
                }, remainingTime);
            });
    }

    // callApexMethod2() {
    //     debugger;
    //     this.showSpinner = true;
    //     const startTime = new Date().getTime();
    //     const spinnerDelay = 1000;
        
    //     showForeCastedData({ loggedInUserId: this.currentUserId, productTypeFilter: this.productType })
    //         .then((data) => {
    //             if (data) {
    //                 this.forecastedLineItems = data.map((res) => ({
    //                     Id: res.id,
    //                     ProductName: res.productName,
    //                     ProductCode: res.productCode,
    //                     AllocatedQuantity: res.quantity,
    //                     selected: false,
    //                     isChargesDisabled: true
    //                 }));

    //                 this.forecastedLineItems = this.forecastedLineItems.map((item, idx) => ({
    //                 ...item,
    //                 index: idx + 1
    //             }));


    //                 this.editableForecastedLineItems = JSON.parse(JSON.stringify(this.forecastedLineItems));
    //                 this.showForecastedData = true;
    //             }
    //         })
    //         .catch((error) => {
    //             console.error('Error fetching data:', error);
    //         })
    //         .finally(() => {
    //             const elapsedTime = new Date().getTime() - startTime;
    //             const remainingTime = Math.max(0, spinnerDelay - elapsedTime);
    //             setTimeout(() => {
    //                 this.showSpinner = false;
    //             }, remainingTime);
    //         });
    // }
    callApexMethod3() {
        debugger;
        this.showSpinner = true;
        const startTime = new Date().getTime();
        const spinnerDelay = 1000;
        
        showForeCastedData({ loggedInUserId: this.currentUserId, productTypeFilter: this.productType })
            .then((data) => {
                if (data) {
                    this.forecastedLineItems = data.map((res) => ({
                        Id: res.productId,
                        ProductName: res.productName,
                        ProductCode: res.productCode,
                        AllocatedQuantity: res.adjustedConsumption,
                        selected: false,
                        isChargesDisabled: true
                    }));

                    this.forecastedLineItems = this.forecastedLineItems.map((item, idx) => ({
                    ...item,
                    index: idx + 1
                }));


                    this.editableForecastedLineItems = JSON.parse(JSON.stringify(this.forecastedLineItems));
                    this.showForecastedData = true;
                }
            })
            .catch((error) => {
                console.error('Error fetching data:', error);
            })
            .finally(() => {
                const elapsedTime = new Date().getTime() - startTime;
                const remainingTime = Math.max(0, spinnerDelay - elapsedTime);
                setTimeout(() => {
                    this.showSpinner = false;
                }, remainingTime);
            });
    }
    



    // handleCheckboxChangeForForecast(event) {
    //     const id = event.target.dataset.id;
    //     const item = this.editableForecastedLineItems.find(i => i.Id === id);
    //     if (item) item.selected = event.target.checked;
    // }
    handleCheckboxChangeForForecast(event){
        debugger;
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;

        const item = this.forecastedLineItems.find(i => i.Id === itemId);

        if (isChecked) {
            const alreadySelected = this.selectedItems.some(i => i.Id === itemId);
            if (alreadySelected) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'This product is already added.',
                        variant: 'warning'
                    })
                );


                event.target.checked = false;

                return;

            }

            const updatedItem = { ...item, selected: true, index: this.selectedItems.length + 1 };
            this.selectedItems = [...this.selectedItems, updatedItem];


            this.forecastedLineItems = this.forecastedLineItems.map(i => {
                if (i.Id === itemId) {
                    return { ...i, selected: true };
                }
                return i;
            });

        } else {

            this.selectedItems = this.selectedItems.filter(i => i.Id !== itemId);


            this.forecastedLineItems = this.forecastedLineItems.map(i => {
                if (i.Id === itemId) {
                    return { ...i, selected: false };
                }
                return i;
            });
        }

        this.buttonVisible = this.selectedItems.length > 0;
        this.selectAllCheckedForForecast = this.forecastedLineItems.every(i => i.selected);

    }
    handleSelectAllForForecast(event){
        debugger;
        const isChecked = event.target.checked;
        this.selectAllCheckedForForecast = isChecked;
        this.forecastedLineItems = this.forecastedLineItems.map(item => {
            const updatedItem = {
                ...item,
                selected: isChecked,
                isChargesDisabled: !isChecked
            };
            if (isChecked) {
                if (!this.selectedItems.find(i => i.Id === item.Id)) {
                    this.selectedItems = [...this.selectedItems, updatedItem];
                }
            } else {
                this.selectedItems = this.selectedItems.filter(i => i.Id !== item.Id);
            }
            return updatedItem;
        });

        if (isChecked) {
            this.forecastedLineItems = [];
        }


    }

    handleQuantityChange(event) {
        const id = event.target.dataset.id;
        const item = this.editableForecastedLineItems.find(i => i.Id === id);
        if (item) item.AllocatedQuantity = event.target.value;
    }

    handleDeleteRow(event) {
        const id = event.target.dataset.id;
        const index = this.editableForecastedLineItems.findIndex(i => i.Id === id);
        if (index > -1) {
            this.deletedLineItems.push(this.editableForecastedLineItems[index]);
            this.editableForecastedLineItems.splice(index, 1);
        }
    }

    handleAddRow() {
        const newItem = {
            Id: 'new_' + Date.now(),
            ProductName: '',
            ProductCode: '',
            AllocatedQuantity: 0,
            selected: false,
            isChargesDisabled: false
        };
        this.editableForecastedLineItems = [...this.editableForecastedLineItems, newItem];
    }


    handleFilterChange(event) {
        debugger;
        console.log("Filter changed:", event.detail);
        this.productType = event.detail;
        this.callApexMethod();
    }

    handleSearchInput(event) {
        debugger;
        const searchTerm = event.target.value?.toLowerCase().trim();

        if (searchTerm) {
            this.filteredRequestLineItems = this.requestLineItems.filter(item => {
                const name = (item.ProductName || '').toLowerCase();
                const code = (item.ProductCode || '').toLowerCase();
                return name.includes(searchTerm) || code.includes(searchTerm);
            });

            this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
            this.currentPage = 1;
            this.updatePageData();
        } else {

            this.filteredRequestLineItems = [];
            this.currentPage = 1;
            this.totalPages = 1;
            this.currentPageData = [];
        }

        this.selectAllChecked = this.currentPageData?.length
            ? this.currentPageData.every(item => item.selected)
            : false;
    }

    handleDelete(event) {
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







handleDeleteSelectedItem(event) {
    debugger;
    const itemId = event.target.dataset.id;
    const deletedItem = this.selectedItems.find(item => item.Id === itemId);

    if (deletedItem) {
       
        this.selectedItems = this.selectedItems.filter(item => item.Id !== itemId);
        this.selectedItems = this.selectedItems.map((item, index) => ({
            ...item,
            index: index + 1
        }));

       
        const isForecastedItem = this.forecastedLineItems.find(item => item.Id === itemId);
        if (isForecastedItem) {
            this.forecastedLineItems = this.forecastedLineItems.map(item => {
                if (item.Id === itemId) {
                    return { ...item, selected: false, isChargesDisabled: true };
                }
                return item;
            });
        }

        
        const wasInFilteredList = this.filteredRequestLineItems.some(item => item.Id === itemId);

        if (wasInFilteredList) {
            this.filteredRequestLineItems = this.filteredRequestLineItems.map(item => {
                if (item.Id === itemId) {
                    return { ...item, selected: false, isChargesDisabled: true };
                }
                return item;
            });

        } else {
            
        }

        
        this.totalPages = Math.ceil(this.filteredRequestLineItems.length / this.recordsPerPage);
        this.updatePageData();

        this.currentPageData = [...this.currentPageData.map(item => ({ ...item }))];
        this.selectAllChecked = this.currentPageData.every(item => item.selected);

        
        this.buttonVisible = this.selectedItems.length > 0;
    }
}




    handleQuantityChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const updatedQuantity = parseFloat(event.target.value);
        this.selectedItems = this.selectedItems.map(item => {
            if (item.Id === itemId) {
                item.AllocatedQuantity = updatedQuantity;
            }
            return item;
        });

        this.filteredRequestLineItems = this.selectedItems.filter(item =>
            this.selectedItems.some(selectedItem => selectedItem.Id === item.Id)
        ).map(item => {
            if (item.Id === itemId) {
                return { ...item, AllocatedQuantity: updatedQuantity };
            }
            return item;
        });
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
        this.currentPageData = this.currentPageData.map(item => {
            const updatedItem = {
                ...item,
                selected: isChecked,
                isChargesDisabled: !isChecked
            };
            if (isChecked) {
                if (!this.selectedItems.find(i => i.Id === item.Id)) {
                    this.selectedItems = [...this.selectedItems, updatedItem];
                    this.buttonVisible = true;
                }
            } else {
                this.selectedItems = this.selectedItems.filter(i => i.Id !== item.Id);
            }
            return updatedItem;
        });

        if (isChecked) {
            this.currentPageData = [];
        }
    }


    handleCheckboxChange(event) {
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;

        const item = this.currentPageData.find(i => i.Id === itemId);

        if (isChecked) {
            const alreadySelected = this.selectedItems.some(i => i.Id === itemId);
            if (alreadySelected) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'This product is already added.',
                        variant: 'warning'
                    })
                );


                event.target.checked = false;

                return;

            }

            const updatedItem = { ...item, selected: true, index: this.selectedItems.length + 1 };
            this.selectedItems = [...this.selectedItems, updatedItem];


            this.currentPageData = this.currentPageData.map(i => {
                if (i.Id === itemId) {
                    return { ...i, selected: true };
                }
                return i;
            });

        } else {

            this.selectedItems = this.selectedItems.filter(i => i.Id !== itemId);


            this.currentPageData = this.currentPageData.map(i => {
                if (i.Id === itemId) {
                    return { ...i, selected: false };
                }
                return i;
            });
        }

        this.buttonVisible = this.selectedItems.length > 0;
        this.selectAllChecked = this.currentPageData.every(i => i.selected);
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
            return;
        }
        const updatedItems = this.selectedItems.map(item => ({
            Id: item.Id,
            QuantityRequested: parseFloat(item.AllocatedQuantity),
            Product2Id: item.Id,
            ParentId: this.PoCreatedRecordId
        }));
        console.log('updatedItems === >' + updatedItems);
        var jsondatatopass = JSON.stringify(updatedItems);
        debugger;
        createProductRequestLineItems({ jsonData: jsondatatopass })
            .then(result => {
                if (result != null && result === 'SUCCESS') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'SUCCESS',
                            message: 'Records Created Successfully!',
                            variant: 'success'
                        })
                    );
                    this.updatedValues.clear();
                    this.closeModal();
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
                console.log('Error : ' + error);
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

    methodToCreatePORecords() {
        debugger;
        const hasZeroQuantity = this.methodToCheckZeroQuntiry();
        if (hasZeroQuantity) {
            return;
        }
        this.showProductSpinner = true;
        setTimeout(() => {
            createPurchaseorder({ shipmentType: this.recordId.shipmentType, loggedInUserId: this.recordId.loggedInUserId, ProductType: this.productType }).then(result => {
                if (result && result != null) {
                    this.PoCreatedRecordId = result;
                    this.handleUpdateProcess();
                } else {
                    alert('something went wrong !');
                }
            })
                .catch(error => {
                    console.log('Error = >' + error);
                })
                .finally(() => {
                    this.showProductSpinner = false;
                    this.buttonVisible = false;
                })

        }, 2000)
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
        //var selectedQLIList = this.filteredRequestLineItems;
        var selectedQLIList = this.selectedItems;
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
    disconnectedCallback() {
        this.removeEventListener('filterchange', this.handleFilterChange);
    }


    handleShowRemainingComponent() {

    this.showRemainingComponent = true;
    this.hidebutton=false;
    this.goBackToForecast=true;
}
handleGoBack(){
   this.showRemainingComponent = false;
   this.hidebutton=true;
   this.goBackToForecast=false;
}

}