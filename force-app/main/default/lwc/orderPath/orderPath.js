import { LightningElement, api, wire, track } from "lwc";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ORDER_OBJECT from "@salesforce/schema/Order";
import STATUS_FIELD from "@salesforce/schema/Order.Status";
import CANCEL_ORDER_FIELD from "@salesforce/schema/Order.Cancel_Order__c";

const FIELDS = [STATUS_FIELD, CANCEL_ORDER_FIELD];

export default class OrderPath extends LightningElement {
    @api recordId;
    @track status;
    @track steps = [];
    @track cancelOrder;
    @track isBooking = false;
    @track isPaymentAndAllocation = false;
    @track isPreInvoice = false;
    @track isInvoiceAndInsurance = false;
    @track isRTORegistration = false;
    @track isReadyForDelivery = false;

    connectedCallback() {
        debugger;
        if (this.recordId == null) {
            const url = window.location.href.toString();
            const queryParams = url.split("&");
            const recordIdParam = queryParams.find(param => param.includes("recordId"));
            if (recordIdParam) {
                const recordIdKeyValue = recordIdParam.split("=");
                if (recordIdKeyValue.length === 2) {
                    const recordId = recordIdKeyValue[1];
                    this.recordId = recordId;
                } else {
                    console.error("Invalid recordId parameter format");
                }
            } else if (recordIdParam == undefined) {
                const url = window.location.href;
                const match = url.match(/\/order\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                    console.log('Record Id:', this.recordId);
                }
            }

            else {
                console.error("recordId parameter not found in the URL");
            }
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: ORDER_OBJECT,
        recordTypeId: "012F4000000db8GIAQ"
    })
    picklistValues({ error, data }) {
        debugger;
        if (data) {
            this.allSteps = data.picklistFieldValues.Status.values.map(item => {
                return {
                    label: item.label,
                    value: item.value
                };
            });
            this.filterSteps();
        } else if (error) {
            console.error("Picklist error", error);
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    wiredOrder({ data, error }) {
        debugger;
        if (data) {
            this.status = getFieldValue(data, STATUS_FIELD);
            this.cancelOrder = getFieldValue(data, CANCEL_ORDER_FIELD);
            this.filterSteps();
            this.updateStageFlags();
        } else if (error) {
            console.error("Record fetch error", error);
        }
    }

    filterSteps() {
        debugger;
        if (!this.allSteps) return;

        if (this.cancelOrder) {
            this.steps = this.allSteps.filter(step => step.value === "Cancellation Requested" || step.value === "Order Cancelled");
        } else {
            this.steps = this.allSteps.filter(step => step.value !== "Cancellation Requested" && step.value !== "Order Cancelled");
        }
    }

    updateStageFlags() {
        this.isBooking = false;
        this.isPaymentAndAllocation = false;
        this.isPreInvoice = false;
        this.isInvoiceAndInsurance = false;
        this.isRTORegistration = false;
        this.isReadyForDelivery = false;
        this.isVehicleDelivered = false;

        switch (this.status) {
            case "Booking":
                this.isBooking = true;
                break;
            case "Payment and Allocation":
                this.isPaymentAndAllocation = true;
                break;
            case "Pre Invoice":
                this.isPreInvoice = true;
                break;
            case "Invoice and Insurance":
                this.isInvoiceAndInsurance = true;
                break;
            case "RTO Registration":
                this.isRTORegistration = true;
                break;
            case "Ready For Delivery":
                this.isReadyForDelivery = true;
                break;
            case "Vehicle Delivered":
                this.isVehicleDelivered = true;
                break;
            default:
                break;
        }
    }
}