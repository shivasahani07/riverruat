import getShipmentItemList from '@salesforce/apex/clainAndShipmentItemController.getShipmentItemList';
import updateShipmentItemList from '@salesforce/apex/clainAndShipmentItemController.updateShipmentItemList';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';



export default class ShipmentItemPopulationAfterGRN extends LightningElement{
   @api recordId;
   shipmentItemList=[];
   showButtons=false;
   isLoading = false;
   
   
   @wire(getShipmentItemList,{recordId:'$recordId'})
   wiredData({data,error}){
    debugger;
    if(data){
        this.shipmentItemList=data;
        console.log('Shipment Item List===>',data);
        if(data[0].Shipment.Status === 'Dispatched'){
            console.log('Status==>',data[0].Shipment.Status);
            this.showButtons=true;
        }
        

    }else if(error){
        console.log(error);
    }
   }
   handleInputChange(event) {
    const sId = event.target.dataset.id; 
    const fieldName = event.target.dataset.field; 
    let newValue = event.target.value; 

   
    if (newValue === '') {
        newValue = 0;  
    } else {
        newValue = parseFloat(newValue);
    }

    
    if (isNaN(newValue)) {
        newValue = 0;  
    }

    
    this.shipmentItemList = this.shipmentItemList.map((item) => {
        if (item.Id === sId) {
            return { ...item, [fieldName]: newValue }; 
        }
        return item; 
    });

    console.log('Updated Shipment Item List:', JSON.stringify(this.shipmentItemList));
}

handleUpdateProcess() {
    debugger;
    const invalidItems = this.shipmentItemList.filter(item => {
        const hasInput = item.Quantity_Received__c != null || item.Missing_Damaged_Quantity__c != null;
         if (!hasInput) return false;
         
        const quantityReceived = item.Quantity_Received__c;
        const damagedOrMissing = item.Missing_Damaged_Quantity__c;
        const totalQuantity = item.Quantity;

        
        return (
            isNaN(quantityReceived) || 
            quantityReceived < 0 || 
            isNaN(damagedOrMissing) || 
            damagedOrMissing < 0 || 
            (quantityReceived + damagedOrMissing > totalQuantity)
        );
    });

    if (invalidItems.length > 0) {
        this.showToast(
            'Error',
            'Ensure all values are greater than zero and their sum does not exceed the total quantity.',
            'error'
        );
        return;
    }
    this.isLoading = true;
    updateShipmentItemList({ shipmentItemList: this.shipmentItemList,recordId:this.recordId })
        .then(() => {
            this.showToast('Success', 'Update Successful.', 'success');
            setTimeout(() => {
                this.isLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                window.location.href = '/' + this.recordId;
            }, 1500);
            
        })
        .catch((error) => {
            this.isLoading = false;
            this.showToast('Error', 'Something Went Wrong.', 'error');
            console.error('Error during update:', error);
        });
}


   closeQuickAction(){
    this.dispatchEvent(new CloseActionScreenEvent());
   }
   showToast(Title,Message,Variant){
    this.dispatchEvent(
        new ShowToastEvent({
            title:Title,
            message:Message,
            variant:Variant
        })
    )
   }
   
   


}