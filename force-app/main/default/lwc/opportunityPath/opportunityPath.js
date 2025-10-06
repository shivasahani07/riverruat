import { LightningElement, api, wire, track } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";
import STAGE_FIELD from "@salesforce/schema/Opportunity.StageName";

export default class OpportunityPath extends LightningElement {
    @api recordId;
    opportunityRecordTypeId;
    @track stage;
    @track steps = [];
    error;

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
            const match = url.match(/\/opportunity\/([^/]+)/);
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


    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.opportunityRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.opportunityRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$opportunityRecordTypeId", fieldApiName: STAGE_FIELD })
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

    @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD] })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.stage = getFieldValue(data, STAGE_FIELD);
        } else if (error) {
            console.error("Record fetch error", error);
        }
    }
}