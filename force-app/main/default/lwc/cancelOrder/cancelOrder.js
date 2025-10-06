import { LightningElement,api,wire,track} from 'lwc';
import getOrderDetail from '@salesforce/apex/orderCancellationComponentController.getOrderDetail';
import rideRiverLogo from '@salesforce/resourceUrl/Ride_River_Logo_LWC';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import ORDER_OBJECT from "@salesforce/schema/Order";
import CANCELLATION_REASON_FIELD from "@salesforce/schema/Order.Cancellation_Reason__c";
import {CloseActionScreenEvent} from 'lightning/actions';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import updateOrder from '@salesforce/apex/orderCancellationComponentController.updateOrder';
import warningLogo from '@salesforce/resourceUrl/Warning_LOGO';

export default class CancelOrder extends LightningElement {

    @track showSuccessAnimation = false;

    showSpinner=false;
    @track orderData = [];
    @track cancellationReasonPicklistOptions;
    orderRecordTypeId
    
    reason='';
    additionalDetails='';
    accName='';
    accNumber='';
    iFSC = '';
    rideRiverLogo=rideRiverLogo;
    warningLogo=warningLogo;
    showComp = false;
    showFirstScreen=false;
    showSecondScreen = false;
    showWarning=true;

    orderNumber='';
    @api 
    set recordId(value) {
        if(value) {
            this._recordId = value;
            this.callApexClass();
        }
    }
    get recordId() {
        return this._recordId;
    }


    @wire(getObjectInfo, { objectApiName: ORDER_OBJECT })
    results({ error, data }) {
        if (data) {
        this.orderRecordTypeId = data.defaultRecordTypeId;
        this.error = undefined;
        } else if (error) {
        this.orderRecordTypeId = undefined;
        console.log('Error==>',error);
        }
    }
    @wire(getPicklistValues, { recordTypeId: "$orderRecordTypeId", fieldApiName: CANCELLATION_REASON_FIELD })
    picklistResults({ error, data }) {
        debugger;
        if (data) {
            console.log('Picklist==>',data);
        this.cancellationReasonPicklistOptions = data.values.map(plValue => {
         return {
            label: plValue.label,
            value: plValue.value
         }
        })
        }else if (error) {
            console.log('Error==>',error);
            }
        }

    connectedCallback() {
        this.callApexClass();
    }

    callApexClass(){
        debugger;
         getOrderDetail({recordId:this.recordId})
        .then(result=>{
            this.orderData = result;
            console.log('Order Data===>',result);
            if((result.Status == 'Booking' || result.Status == 'Payment and Allocation' || result.Status == 'Pre Invoice' || result.Status == 'Invoice and Insurance')){
                this.orderNumber=result.OrderNumber;
                this.showComp = true;
                this.showFirstScreen=true;
                this.showWarning=false;
            }
        })
        .catch(error=>{
            console.log('Error==>',error);
        })
    }
    
    handleReasonChange(event){
        debugger;
        this.reason=event.detail.value;
        event.target.setCustomValidity('');
        event.target.reportValidity();

        console.log('Reason==>',this.reason);

    }
    handleAddDetailsChange(event){
        debugger;
        this.additionalDetails= event.target.value;
        event.target.setCustomValidity('');
        event.target.reportValidity();

    }
    handleAccountSection(){
        if(this.validateSenondPageNavigation()){
          this.showSecondScreen = true;
          this.showFirstScreen = false;
        }
        
            
        
    }
    handleCloseScreen(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handlePreviousPage(){
        this.showSecondScreen = false;
         this.showFirstScreen = true;
    }
    handleSubmit(){
        debugger;
        if(this.validateSubmission()){
            this.showSpinner=true;
            setTimeout(()=>{
              updateOrder({reason:this.reason,additionalDetails:this.additionalDetails,accName:this.accName,accNumber:this.accNumber,iFSC:this.iFSC,recordId:this.recordId})
            .then((result)=>{
                if(result == 'Success'){
                    this.showToast('Success','Cancellation Request Is In Progress','success');
                    
                    this.showFirstScreen = false;
                    this.showSecondScreen = false;
                    this.showWarning = false;
                    this.showSuccessAnimation = true;

                    setTimeout(() => {
                        let baseUrl = window.location.origin;
                        console.log('baseUrl=>',baseUrl);
                        let currentUrl = window.location.href;

                        if (currentUrl.includes("lightning.force.com")) {
                           window.location.href = `/lightning/r/Order/${this.recordId}/view`;
                        }else{
                           window.location.href = `${baseUrl}/autocloudSite/s/order/${this.recordId}/${this.orderNumber}`;
                        }

                        
                        this.handleCloseScreen();
                    }, 4000); 
                }else{
                    this.showToast('Error','Something went wrong !!!','error')
                }
                this.showSpinner=false;
            })
            .catch(error=>{
                console.log('Error==>',error);
                this.showSpinner=false;
            })
            },3000)
            
        }

    }
    handleAccountNameChange(event){
         this.accName=event.target.value;
         event.target.setCustomValidity('');
         event.target.reportValidity();
    }
    handleAccountNumberChange(event){
        this.accNumber=event.target.value;
        event.target.setCustomValidity('');
        event.target.reportValidity();
    }
    handleIFSCChange(event){
        this.iFSC=event.target.value;
        event.target.setCustomValidity('');
        event.target.reportValidity();
    }
    showToast(Title,Message,Variant){
        this.dispatchEvent(
            new ShowToastEvent({
              title:Title,
              message:Message,
              variant:Variant
        }))
    }
    validateSenondPageNavigation(){
        debugger;
        let isValid = true;
        let reasonBox = this.template.querySelector(`lightning-combobox[data-id='reasonBox']`);
        let addDetBox = this.template.querySelector(`lightning-input[data-id='addDetBox']`);

        if(this.reason == 'Others' && (this.additionalDetails == '' )){
            this.showToast('Oops','Please Fill Additional Details','warning');
            addDetBox.setCustomValidity('Please Fill Additional Details');
            isValid = false;
        }else if(this.reason == ''){
            this.showToast('Oops','Please Select a Reason','warning');
            reasonBox.setCustomValidity('Please Select a Reason');
            isValid = false;
        }else{
            addDetBox.setCustomValidity('');
            reasonBox.setCustomValidity('');
        }
        addDetBox.reportValidity();
        reasonBox.reportValidity();

        return isValid;

    }
    validateSubmission() {
    let isEligible = true;

   
    const fields = [
        { ref: this.template.querySelector("lightning-input[data-id='accName']"), value: this.accName, msg: 'Please Fill Account Name' },
        { ref: this.template.querySelector("lightning-input[data-id='accNumber']"), value: this.accNumber, msg: 'Please Fill Account Number' },
        { ref: this.template.querySelector("lightning-input[data-id='ifsc']"), value: this.iFSC, msg: 'Please Fill IFSC' }
    ];

    fields.forEach(field => {
        if (!field.value || field.value.trim() === '') {
            field.ref.setCustomValidity(field.msg);
            isEligible = false;
        } else {
            field.ref.setCustomValidity('');
        }
        field.ref.reportValidity();
    });

    if (!isEligible) {
        this.showToast('Warning', 'Please fill all the required details', 'warning');
    }

    return isEligible;
}

}