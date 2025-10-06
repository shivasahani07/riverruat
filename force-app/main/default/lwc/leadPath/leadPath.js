import { LightningElement, api, wire, track } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import STATUS_FIELD from "@salesforce/schema/Lead.Status";

export default class LeadPath extends LightningElement {
    @api recordId;
    leadRecordTypeId;
    @track status;
    error;
    @track steps = [];

    connectedCallback() {
        debugger;
        if(this.recordId == null){
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
            } else if(recordIdParam == undefined){
            const url = window.location.href;
            const match = url.match(/\/lead\/([^/]+)/);
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

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.leadRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.leadRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$leadRecordTypeId", fieldApiName: STATUS_FIELD })
    picklistValues({ data, error }) {
        if (data) {
            this.steps = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.steps = [];
        }
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD] })
    wiredLead({ data, error }) {
        if (data) {
            this.status = getFieldValue(data, STATUS_FIELD);
        } else if (error) {
            console.error("Record fetch error", error);
        }
    }
}