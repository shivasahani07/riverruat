/**
 * @author Dinesh Baddawar
 * @email dinesh.butilitarianlab@gmail.com
 * @create date 2024-12-10 11:00:42
 * @modify date 2024-12-20 20:38:52
 * @desc [Component to update Receive GRN]
 */

import getPOrelatedPLI from '@salesforce/apex/bulkreceiveGRNController.getPOrelatedPLI';
import getShipmentDetail from '@salesforce/apex/bulkreceiveGRNController.getShipmentDetail';
import { CurrentPageReference } from 'lightning/navigation';
import updateShipmentItemQuantities from '@salesforce/apex/bulkreceiveGRNController.updateShipmentItemQuantities';
import createDiscrepancyAndLineitem from '@salesforce/apex/bulkreceiveGRNController.createDiscrepancyAndLineitem';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track, wire } from 'lwc';
export default class BulkrecieveGRN extends LightningElement {
    @api recordId;
    @track requestLineItems = [];
    @track updatedValues = {};
    @track selectAllChecked = false;
    @track isSubmitDisabled = false;
    showSpinner = false;
    ShowGRNDone = false;
    secondScreen = false;
    connectedCallback() {
        debugger;
         if (!this.recordId) {
            const url = window.location.href;
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));

            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    this.recordId = recordIdKeyValue[1];
                }
            } else {
                const match = url.match(/\/Shipment\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                }
            }
        }
    
        if (this.recordId) {
            this.getShipmentDetailApex();
        }
    }
    


    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageReference) {
        debugger;
        if (currentPageReference) {
            if (currentPageReference.attributes.recordId != undefined) {
                this.recordId = currentPageReference.attributes.recordId;
            }
        }
    }

    getShipmentDetailApex() {
        debugger;
        getShipmentDetail({ recordId: this.recordId }).then(result => {
            if (result != null) {
                if (result.Is_Discrepancy_Created__c === true) {
                    this.ShowGRNDone = true;
                } else {
                    this.ShowGRNDone = false;
                    this.CallDetailsMethod();
                }
            }
        })
    }

     CallDetailsMethod() {
         debugger;
         getPOrelatedPLI({ recordId: this.recordId }).then(data => {
             if (data) {
                 debugger;
                 this.requestLineItems = data.map((res) => ({
                     Id: res.Id,
                     Name: res.Product2?.Name,
                     ProductId:res.Product2Id,
                     ProductName: res.Product2?.Name || 'N/A',
                     PartName: res.Product2?.ProductCode || 'N/A',
                     Product2Id: res.Product2?.Id || null,
                     QuantityRequested: res.Quantity,
                     ShipmentId: res.ShipmentId,
                     DestinationLocationId: res.Shipment.DestinationLocationId,
                     SourceLocationId: res.Shipment.SourceLocationId,
                     RecievedQuantity: res.Received_Quantity__c,
                     selected: false,
                     isChargesDisabled: true,
                     isChagesDisabled: true
                 }));
                 this.showSpinner = false;
                 this.error = undefined;
                 console.log('Fetched Data==>',data);
             } else if (error) {
                 this.error = error;
                 this.requestLineItems = [];
                 console.error('Error fetching product request items == >', error);
             }
         })
     } 

    //  handleInputChange(event) {
    //     debugger;
    //     const rowId = event.target.dataset.id;
    //     const fieldName = event.target.name;
    //     const updatedValue = fieldName === 'remarks' ? event.target.value : parseFloat(event.target.value) || 0;
    
    //     console.log(`Field Updated: ${fieldName}, Value: ${updatedValue}`);
    //     if (!this.updatedValues[rowId]) {
    //         this.updatedValues[rowId] = {
    //             Id: rowId,
    //             receivedQuantity: null,
    //             MIT: null,
    //             DIT: null,
    //             WP: null,
    //             remarks: '', 
    //             isChargesDisabled: false 
    //         };
    //     }
    
    //     if (fieldName === 'recQuantity') {
    //         this.updatedValues[rowId]['receivedQuantity'] = updatedValue;
    //     } else if (fieldName === 'remarks') {
    //         this.updatedValues[rowId]['remarks'] = updatedValue;  
    //     } else {
    //         this.updatedValues[rowId][fieldName] = updatedValue;
    //     }
    
    //     let selectedItem = this.requestLineItems.find(item => item.Id === rowId);
    //     if (!selectedItem) return;
    
        
    //     let totalValue =
    //         (parseFloat(this.updatedValues[rowId].receivedQuantity) || 0) +
    //         (parseFloat(this.updatedValues[rowId].MIT) || 0) +
    //         (parseFloat(this.updatedValues[rowId].DIT) || 0) +
    //         (parseFloat(this.updatedValues[rowId].WP) || 0);
    
    //     console.log(`Total Value for ${rowId}: ${totalValue}, Expected: ${selectedItem.QuantityRequested}`);
    
    //     if (totalValue > selectedItem.QuantityRequested) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Error',
    //                 message: 'Sum of Received Quantity, MIT, DIT, and WP should not exceed Shipped Quantity.',
    //                 variant: 'error'
    //             })
    //         );
    //         this.isSubmitDisabled = true;
    //     } else {
    //         this.isSubmitDisabled = false;
    //     }
    
    //     if (this.updatedValues[rowId].receivedQuantity === selectedItem.QuantityRequested) {
    //         this.updatedValues[rowId].MIT = null;
    //         this.updatedValues[rowId].DIT = null;
    //         this.updatedValues[rowId].WP = null;
    //         this.updatedValues[rowId].isChargesDisabled = true;
    //     } else {
    //         this.updatedValues[rowId].isChargesDisabled = false;
    //     }
    
    //     this.requestLineItems = this.requestLineItems.map(item => ({
    //         ...item,
    //         isChargesDisabled: this.updatedValues[item.Id]?.isChargesDisabled || false
    //     }));
    
    //     console.log('Updated Values:', JSON.stringify(this.updatedValues));
    //     console.log('Submit Button Disabled:', this.isSubmitDisabled);
    // }
    
    handleInputChange(event) {
        debugger;
        const rowId = event.target.dataset.id;
        const fieldName = event.target.name;
        const updatedValue = fieldName === 'remarks' ? event.target.value : parseFloat(event.target.value) || 0;
    
        console.log(`Field Updated: ${fieldName}, Value: ${updatedValue}`);
        //added by Aniket
        let selectedItem = this.requestLineItems.find(item => item.Id === rowId);
    if (!selectedItem) {
        console.warn(`No matching item found for rowId: ${rowId}`);
        return; // Avoid further execution if no matching item is found
    }
        //upto here, recordId: this.recordId

        
        if (!this.updatedValues[rowId]) {
            this.updatedValues[rowId] = {
                Id: rowId,
                ProductId: selectedItem?.Product2Id || null,//added by Aniket to capture producId
                receivedQuantity: null,
                MIT: null,
                DIT: null,
                WP: null,
                Extra: null,  // ✅ Added Extra Field
                remarks: '', 
                isChargesDisabled: false 
            };
        }
    
        if (fieldName === 'recQuantity') {
            this.updatedValues[rowId]['receivedQuantity'] = updatedValue;
        } else if (fieldName === 'remarks') {
            this.updatedValues[rowId]['remarks'] = updatedValue;  
        } else {
            this.updatedValues[rowId][fieldName] = updatedValue;
        }
    
        console.log('Updated Values:', JSON.stringify(this.updatedValues));
    }
  
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;
        this.selectAllChecked = isChecked;
        this.requestLineItems = this.requestLineItems.map(item => ({
            ...item,
            selected: isChecked,
            isChargesDisabled: !isChecked,
            isChagesDisabled: !isChecked
        }));
    }

    handleCheckboxChange(event) {
        debugger;
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        this.requestLineItems = this.requestLineItems.map(item => {
            if (item.Id === itemId) {
                return {
                    ...item,
                    selected: isChecked,
                    isChargesDisabled: !isChecked,
                    isChagesDisabled: !isChecked
                };
            }
            return item;
        });
        this.selectAllChecked = this.requestLineItems.every(item => item.selected);
    }

    handleUpdateProcess() {
        debugger;
        let filteredUpdates = {};
        let matchingUpdates = {};
        let isQuantityMismatch = false;

        Object.keys(this.updatedValues).forEach((rowId) => {
            let updatedItem = this.updatedValues[rowId];
            let originalItem = this.requestLineItems.find(item => item.Id === rowId);

            if (originalItem) {

                let totalValue =
                    (parseFloat(updatedItem.receivedQuantity) || 0) +
                    (parseFloat(updatedItem.MIT) || 0) +
                    (parseFloat(updatedItem.DIT) || 0) +
                    (parseFloat(updatedItem.WP) || 0);
    
                if (totalValue < originalItem.QuantityRequested) {
                    isQuantityMismatch = true;
                }   

                if (updatedItem.receivedQuantity !== originalItem.QuantityRequested) {
                    filteredUpdates[rowId] = updatedItem;
                } else {
                    // matchingUpdates[rowId] = updatedItem;
                    matchingUpdates[rowId] = {
                        ...updatedItem,
                        remarks: updatedItem.remarks || ''
                    };
                }
            }
        });
        if (isQuantityMismatch) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Sum of Received Quantity, MIT, DIT, and WP cannot be less than Shipped Quantity.',
                    variant: 'error'
                })
            );
            return;
        }

        if (Object.keys(filteredUpdates).length === 0) {
            updateShipmentItemQuantities({ updatedItemsJson: JSON.stringify(matchingUpdates ) })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'SUCCESS',
                            message: 'Records updated successfully',
                            variant: 'success'
                        })
                    );
                    this.updatedValues = {};
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error updating records: ' + error.body.message,
                            variant: 'error'
                        })
                    );
                    console.error('Error updating shipment items:', error);
                });
           // return;
        }

        createDiscrepancyAndLineitem({ updatedItems: JSON.stringify(filteredUpdates), recordId: this.recordId })
            .then((result) => {
                debugger;
                if (result === 'SUCCESS') {  
                    debugger;
                    this.showSpinner = false;
                    this.secondScreen = true;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'SUCCESS',
                            message: 'Records updated successfully',
                            variant: 'success'
                        })
                    );
                    this.updatedValues = {};
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error updating records: ' + error.body.message,
                        variant: 'error'
                    })
                );
                console.error('Error updating records:', error);
            });
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }


}