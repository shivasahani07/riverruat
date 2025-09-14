import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAvailableQuantity from '@salesforce/apex/WorkOrderLineItemController.getAvailableQuantity';
import getPricebookEntry from '@salesforce/apex/WorkOrderLineItemController.getPricebookEntry';
import createWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.createWorkOrderLineItems';
import getRelatedWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.getRelatedWorkOrderLineItems';
import getWarrantyForJobCard from '@salesforce/apex/WorkOrderLineItemController.getWarrantyForJobCard';
import VeripartWithActionWithPlanApex from '@salesforce/apex/TFRController.VeripartWithActionWithPlanApex';
import getFailureCode from '@salesforce/apex/AddFailureCodeController.getFailureCode';

import checkTFRValidation from '@salesforce/apex/TFRController.checkTFRValidation';
import LightningAlert from 'lightning/alert';

const STATUS_FIELD = 'WorkOrder.Status';
const VIN_FIELD = 'WorkOrder.Vehicle_Identification_Number__c';
const BLOCKED_STATUSES = new Set([
    'Ready for Delivery',
    'Submit For Approval',
    'Cancellation Requested',
    'Canceled',
    'Completed'
]);
const EDITABLE_STATUSES = new Set(['New', 'In Progress', 'Re work']);

const WARRANTY_PRIOR_APPLICABLE = new Set(['River Warranty', 'EW(Extended Warranty)', 'Goodwill Warranty', 'Parts Warranty'])

export default class BulkInsertJCProductsCustom extends NavigationMixin(LightningElement) {
    @api recordId;
    @track itemList = [];
    @track existingWorkOrderLineItems = [];
    @track warrantyId;
    @track showAll = false;
    @track hasErrorInList = false;
    @track isLoading = false;
    @track currentVinNo;
    @track expandedRows = [];
    activeProductFilter = [
        {
            fieldName: 'IsActive',
            operator: 'eq',
            value: true
        }
    ];

    @track ActionPlanProducts = [];
    @track ActionPlanlabours = [];

    keyIndex = 0;
    refreshResultData;

    get options() {
        this.options = this.data.map(item => {
            return {
                label: item.Name,
                value: item.Id
            };
        });
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
    }

    // Picklist options
    filteredReplacementTypeOptions = [
        { label: 'Paid', value: 'Paid' },
        { label: 'River Warranty', value: 'River Warranty' },
        { label: 'Insurance', value: 'Insurance' },
        { label: 'EW(Extended Warranty)', value: 'EW(Extended Warranty)' },
        { label: 'Goodwill Warranty', value: 'Goodwill Warranty' },
        { label: 'Parts Warranty', value: 'Parts Warranty' }
    ];

    replacementTypeOptions = [
        { label: 'Causal', value: 'Causal' },
        // { label: 'Non-Causal', value: 'Non-Causal' }
    ];

    treeColumns = [
        {
            type: 'text', fieldName: 'displayName', label: 'Product', initialWidth: 300,
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Part No', fieldName: 'partUrl', type: 'url', typeAttributes: { label: { fieldName: 'displayName' }, target: '_blank' },
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        { type: 'text', fieldName: 'ProductCode', label: 'Part Code' },
        { type: 'text', fieldName: 'Replacement_Type__c', label: 'Part Type' },
        { type: 'number', fieldName: 'Quantity', label: 'Quantity', initialWidth: 120 },
        { type: 'text', fieldName: 'RR_Parts_Category__c', label: 'Parts Category' },
        { type: 'text', fieldName: 'Status', label: 'Status' }
    ];

    // LIFECYCLE HOOKS
    connectedCallback() {
        this.fetchWarranty();
        this.addParentRow();
        this.VeripartWithActionWithPlan(this.recordId);
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD, VIN_FIELD] })
    wiredWorkOrder({ error, data }) {
        debugger;
        if (data) {
            const status = data.fields.Status.value;
            this.currentVinNo = data.fields.Vehicle_Identification_Number__c.value;
            this.showAll = EDITABLE_STATUSES.has(status) && !BLOCKED_STATUSES.has(status);
        }
        if (error) this.handleError('Error loading work order status', error);
    }

    @wire(getRelatedWorkOrderLineItems, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        debugger;
        this.refreshResultData = result;
        if (result.data) {
            this.processExistingItems(result.data);
            // this.currentVinNo = result.data[0]?.WorkOrder?.Vehicle_Identification_Number__c;
        }
        else if (result.error) this.handleError('Error loading existing line items', result.error);
    }

    processExistingItems(rawItems) {
        const items = JSON.parse(JSON.stringify(rawItems));
        const itemMap = new Map();
        const rootItems = [];

        // Initialize items without _children property
        items.forEach(item => {
            // Only add _children if item will have children
            item.displayName = item.PricebookEntry?.Product2?.Name || item.Name;
            item.ProductCode = item.PricebookEntry?.Product2?.ProductCode || '';
            item.rowClass = item.Part__c ? 'slds-text-color_weak' : '';
            item.partUrl = `/${item.Id}`;
            item.productUrl = item.PricebookEntry?.Product2Id ? `/${item.PricebookEntry.Product2Id}` : '';
            item.Replacement_Type__c = item.Replacement_Type__c;
            item.productId = item.Product2Id;
            itemMap.set(item.Id, item);
        });

        // Build hierarchy - only add _children when needed
        items.forEach(item => {
            if (item.Part__c && itemMap.has(item.Part__c)) {
                const parent = itemMap.get(item.Part__c);
                if (!parent._children) {
                    parent._children = []; // Initialize only when needed
                }
                parent._children.push(item);
            }
        });

        // Identify root items
        items.forEach(item => {
            if (!item.Part__c || !itemMap.has(item.Part__c)) {
                rootItems.push(item);
            }
        });

        console.log(`existing parts--${JSON.stringify(rootItems)}`);
        this.existingWorkOrderLineItems = rootItems;
        this.expandedRows = rootItems.map(item => item.Id);
    }

    // ROW MANAGEMENT
    addParentRow() {
        this.keyIndex++;
        this.itemList = [
            ...this.itemList,
            this.createRowObject(this.keyIndex, false)
        ];
    }

    addChildProduct(event) {
        debugger;
        const parentIndex = parseInt(event.target.dataset.id, 10);
        const parentItem = this.itemList[parentIndex];

        if (!parentItem.productId) {
            this.showError(parentIndex, 'Please select a product before adding consequential products');
            return;
        }

        this.clearError(parentIndex);
        this.addChildRow(parentIndex);
    }

    addChildRow(parentIndex) {
        this.keyIndex++;
        const parentId = this.itemList[parentIndex].id;
        const childRow = this.createRowObject(this.keyIndex, true, parentId);
        const insertPosition = this.findLastChildIndex(parentId) + 1 || parentIndex + 1;

        this.itemList.splice(insertPosition, 0, childRow);
        this.itemList = [...this.itemList];
        this.itemList[parentIndex].hasChildren = true;
    }

    createRowObject(id, isChild = false, parentId = null) {
        debugger;
        return {
            id: id,
            productId: '',
            quantity: 1,
            partsCategory: this.inheritPropertyfromItsParent(isChild, 'partsCategory', parentId),
            replacementType: '',
            electricalValue: '',
            partDescription: '',
            showAdditionalFields: false,
            hasError: false,
            errorMessage: '',
            isChild: isChild,
            parentId: parentId,
            hasChildren: false,
            cssClass: isChild
                ? 'slds-box slds-m-bottom_medium slds-p-around_medium slds-theme_shade'
                : 'slds-box slds-m-bottom_medium slds-p-around_medium',
            sequence: this.getNextSequenceNumber(isChild, parentId),
            pricebookEntryId: null,
            price: 0,
            availableQuantity: 0,
            productCode: '',
            TFR_Required__c: false,
            RR_Parts_Category__c: this.inheritPropertyfromItsParent(isChild, 'RR_Parts_Category__c', parentId),
            Replacement_Type__c: this.inheritPropertyfromItsParent(isChild, 'Replacement_Type__c', parentId),
            filter: { criteria: [{}, {}] },
            isFailureCodeVisible: false,
            isElectricalValueRequired: false,
            isDisableaddChildProduct: true,
            Post_Vin_cutt_off__c: false,
            isDisbaledProduct: isChild ? false : true,
            isDisbaledProductQuantity: true,
            failureCodeOptions: [],

        };
    }

    getNextSequenceNumber(isChild, parentId) {
        debugger;
        if (!isChild) {
            return this.itemList.filter(item => !item.isChild).length + 1;
        } else {
            const parent = this.itemList.find(item => item.id === parentId);
            if (!parent) return '0.0';
            const childCount = this.itemList.filter(item => item.parentId === parentId).length;
            return `${parent.sequence}.${childCount + 1}`;
        }
    }

    inheritPropertyfromItsParent(isChild, field, parentId) {
        debugger;
        if (isChild) {
            const parent = this.itemList.find(item => item.id === parentId);
            if (!parent) return;

            const fieldValue = parent[field];

            // Also update already added children
            const childs = this.itemList.filter(item => item.parentId === parentId);
            childs.forEach((item) => {
                if (field === 'Replacement_Type__c') {
                    item[field] = 'Consequential';
                } else {
                    item[field] = fieldValue;
                }
            });

            // Return value for initializing a new child row
            // if (field === 'Replacement_Type__c') {
            //     return 'Consequential';
            // }
            return fieldValue;
        }
        return null;
    }

    removeRow(event) {
        const index = parseInt(event.target.dataset.id, 10);
        const item = this.itemList[index];

        if (item.isChild) {
            this.removeChildRow(index);
        } else if (item.hasChildren) {
            if (confirm('This product has consequential products. Remove all?')) {
                this.removeParentAndChildren(index);
            }
        } else {
            this.itemList = this.itemList.filter((_, i) => i !== index);
        }
    }

    removeChildRow(index) {
        const item = this.itemList[index];
        this.itemList = this.itemList.filter((_, i) => i !== index);

        const parentIndex = this.itemList.findIndex(i => i.id === item.parentId);
        if (parentIndex !== -1) {
            const hasChildren = this.itemList.some(i => i.parentId === this.itemList[parentIndex].id);
            this.itemList[parentIndex].hasChildren = hasChildren;
        }
    }

    removeParentAndChildren(parentIndex) {
        const parentId = this.itemList[parentIndex].id;
        this.itemList = this.itemList.filter(item =>
            item.id !== parentId && item.parentId !== parentId
        );
    }

    findLastChildIndex(parentId) {
        let lastIndex = -1;
        this.itemList.forEach((item, index) => {
            if (item.parentId === parentId) lastIndex = index;
        });
        return lastIndex;
    }

    // FIELD HANDLERS
    handleProductChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const productId = event.detail.recordId;
        const indexed = this.itemList[index];

        // if (this.checkActionPlansWithProducts(productId)) {
        //     this.showError(index, `same part found in Action Plans Please check and update`);
        //     return;
        // }

        if (this.itemList[index].RR_Parts_Category__c == '' || this.itemList[index].RR_Parts_Category__c == null) {
            setTimeout(() => {
                const inputEl = this.template.querySelector(`lightning-record-picker[data-id="${index}"]`);
                if (inputEl) {
                    inputEl.value = null;
                    this.showError(index, `You can not add parts without Parts Category`);

                }
            }, 100);

            return;

        }
        let foundDuplicateProductInChild = false;
        for (let i = 0; i < this.itemList.length; i++) {
            if (this.itemList[i].productId == productId && this.itemList[i].isChild) {
                foundDuplicateProductInChild = true
                //  this.showError(i, `You can not add duplicate parts`);
                this.showError(index, `You can not add duplicate parts`);
                return;
            }
            if (this.itemList[i].productId == productId && this.itemList[i].RR_Parts_Category__c == this.itemList[index].RR_Parts_Category__c && !this.itemList[index].isChild) {
                foundDuplicateProductInChild = true
                this.showError(index, `You can not add duplicate parts in :`);
                return;
            }
        }

        if (foundDuplicateProductInChild) {
            this.showToast('Error', 'You can not add duplicate parts in same Causal', 'error');
            this.showError(index, `You can not add duplicate parts in same Causal:`);
            return
        }

        this.itemList[index].productId = productId;
        const rules = [
            { fields: ["productId", "RR_Parts_Category__c"] }           // rule 2: same name + phone
        ];
        let tempMergedList = []
        tempMergedList = [...this.existingWorkOrderLineItems, ...this.itemList];
        let foundDuplucatesRecords = this.applyDuplicateRules(tempMergedList, rules);
        if (foundDuplucatesRecords.productId_RR_Parts_Category__c.length > 0) {
            console.log(JSON.stringify('foundDuplucatesRecords', foundDuplucatesRecords));
            this.showError(index, 'you can not repeat same product with same categories')
            return;
        }

        productId ? this.fetchProductDetails(index, productId) : this.clearProductDetails(index);
    }

    findParentduplicateparts() {
        debugger;
    }

    async fetchProductDetails(index, productId) {
        debugger;
        try {
            const prepareData = await getPricebookEntry({ productId });
            const { returnPriceBook, EffectedParts } = prepareData;

            this.itemList[index] = {
                ...this.itemList[index],
                pricebookEntryId: returnPriceBook.Id,
                price: returnPriceBook.UnitPrice,
                productCode: returnPriceBook.Product2?.ProductCode,
                TFR_Required__c: !!EffectedParts,
                TFR_Required_object: EffectedParts,
                // isFailureCodeVisible: !!EffectedParts
            };

            const availableQuantity = await getAvailableQuantity({
                productId,
                workOrderId: this.recordId
            });

            this.itemList[index].availableQuantity = availableQuantity;

            this.setFailureCodeFilter(index, EffectedParts?.Id);
            this.validateQuantity(index);
        }
        catch (error) {
            this.showError(index, `Error fetching product details: ${error.body?.message || error.message}`);
        }
    }

    setFailureCodeFilter(index, vinCutoff) {
        debugger;
        this.itemList[index].filter = {
            criteria: [
                { fieldPath: 'Is_Active__c', operator: 'eq', value: true },
                // {
                //     fieldPath: vinCutoff ? 'VIN_Cut_off__c' : 'TFR_Part_Effect__c',
                //     operator: 'eq',
                //     value: vinCutoff || this.itemList[index].productId
                // }

                {
                    fieldPath: 'TFR_Part_Effect__c',
                    operator: 'eq',
                    value: vinCutoff
                }
            ]
        };
    }


    clearProducrHtml(index) {

    }

    clearProductDetails(index) {
        this.itemList[index] = {
            ...this.itemList[index],
            pricebookEntryId: null,
            price: 0,
            productCode: '',
            availableQuantity: 0,
            TFR_Required__c: false,
            isFailureCodeVisible: false,
            Failure_Code__c: null
        };
        this.clearError(index);
    }

    handleQuantityChange(event) {
        debugger;
        const index = event.target.dataset.id;
        this.itemList[index].quantity = event.target.value;
        this.validateQuantity(index);
    }

    validateQuantity(index) {
        const item = this.itemList[index];
        let error = '';

        if (item.quantity <= 0) error = 'Quantity must be greater than 0';
        else if (item.quantity > item.availableQuantity) {
            error = `Quantity exceeds available stock (${item.availableQuantity})`;
            this.itemList[index].isDisbaledProductQuantity = true;
        }
        else this.itemList[index].isDisbaledProductQuantity = false;
        error ? this.showError(index, error) : this.clearError(index);
    }

    handlePicklistChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const fieldName = event.target.dataset.fieldname;
        const value = event.detail.value;
        this.itemList[index].isDisableaddChildProduct = true;
        this.itemList[index].Replacement_Type__c = null;
        this.itemList[index].replacementType = null;
        this.itemList[index][fieldName] = value;

        if (fieldName === 'RR_Parts_Category__c') {
            this.itemList[index].showAdditionalFields = value !== 'Paid';
            this.itemList[index].isElectricalValueRequired = false;
            this.itemList[index]['partsCategory'] = this.itemList[index]['RR_Parts_Category__c']
            this.itemList[index].isDisbaledProduct = false;

        }

        if (fieldName === 'Replacement_Type__c') {
            this.itemList[index].isElectricalValueRequired = value === 'Causal';
            this.itemList[index].isDisableaddChildProduct = (!this.itemList[index].isElectricalValueRequired || this.itemList[index].RR_Parts_Category__c != 'River Warranty')
            this.itemList[index].isFailureCodeVisible = (this.itemList[index].TFR_Required__c && value == 'Causal');
            if (this.itemList[index].isFailureCodeVisible) {
                let prodcutId = this.itemList[index].prodcutId;
                let productcode = this.itemList[index].productCode;
                let vinCuttoff = this.itemList[index].TFR_Required_object.Id
                // this.itemList[index].Replacement_Type__c = 'Causal';
                this.getFailureCodes(vinCuttoff, index);
            }
        }
    }

    async getFailureCodes(tfrPEId, index) {
        try {
            const data = await getFailureCode({ tfrPEId });

            this.itemList[index].failureCodeOptions = data.map(item => ({
                label: item.Name,
                value: item.Id
            }));

            console.log(
                'Failure Code Options: ',
                JSON.stringify(this.itemList[index].failureCodeOptions)
            );
        } catch (error) {
            console.error('Error fetching failure codes: ', error);
        }
    }



    async handleFailureCodeChange(event) {
        debugger;
        const index = event.target.dataset.id;
        let value = event.target.value;
        const fieldName = event.target.dataset.fieldname;
        this.itemList[index].Failure_Code__c = value;

        await this.checkTFRApplicable(
            this.currentVinNo,
            this.itemList[index].Failure_Code__c,
            index
        );
    }

    async checkTFRApplicable(VINno, FailureCodeId, index) {
        debugger;
        try {
            const returndata = await checkTFRValidation({ VINno, FailureCodeId });
            this.itemList[index].TFR_Required__c = returndata.isTFRApplicable;
            this.itemList[index].Post_Vin_cutt_off__c = returndata.isPostVinCuttoff;
        }
        catch (error) {
            this.itemList[index].TFR_Required__c = false;
            console.error('TFR Validation Error:', error);
        }
    }

    handleInputChange(event) {
        const index = event.target.dataset.id;
        const fieldName = event.target.dataset.fieldname;
        this.itemList[index][fieldName] = event.target.value;
    }

    // FORM SUBMISSION
    async handleSubmit() {
        debugger;
        this.isLoading = true;
        console.log('Before Processing', JSON.stringify(this.itemList))
        if (!this.validateForm()) {
            this.isLoading = false;
            return;
        }

        let tempMergedList = []
        const rules = [
            { fields: ["productId", "RR_Parts_Category__c"] }           // rule 2: same name + phone
        ];
        tempMergedList = [...this.existingWorkOrderLineItems, ...this.itemList];
        let foundDuplucatesRecords = this.applyDuplicateRules(tempMergedList, rules);
        if (foundDuplucatesRecords.productId_RR_Parts_Category__c.length > 0) {
            console.log(JSON.stringify('foundDuplucatesRecords', foundDuplucatesRecords));
            // this.showError(index, 'you can not repeat same product with same categories')
            this.isLoading = false;
            this.showToast('Error', 'you can not repeat same product with same categories', 'error');
            return;
        }

        try {
            const lineItems = this.prepareLineItems();
            console.log('After Processing', JSON.stringify(lineItems))
            await createWorkOrderLineItems({ lineItems });
            this.showToast('Success', 'Products added successfully', 'success');
            await refreshApex(this.refreshResultData);
            this.resetForm();
            this.isLoading = false;
        }
        catch (error) {
            this.handleError('Failed to add products', error);
        }
        finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        let isValid = true;

        this.itemList.forEach((item, index) => {
            let error = '';

            if (!item.productId) error = 'Please select a product';
            else if (item.quantity <= 0 || item.quantity > item.availableQuantity) {
                error = 'Invalid quantity';
            }
            else if (item.isChild && !item.parentId) {
                error = 'Consequential product missing parent';
            }

            if (error) {
                this.showError(index, error);
                isValid = false;
            }
        });

        if (!isValid) {
            this.showToast('Error', 'Please fix all errors before submitting', 'error');
        }

        return isValid;
    }

    prepareLineItems() {
        debugger;
        const idToSequence = {};
        const sortedItems = [
            ...this.itemList.filter(item => !item.isChild),
            ...this.itemList.filter(item => item.isChild)
        ];

        sortedItems.forEach((item, index) => {
            idToSequence[item.id] = index + 1;
        });

        return sortedItems.map(item => {
            const isAddWP = WARRANTY_PRIOR_APPLICABLE.has(item.RR_Parts_Category__c);
            return {
                WorkOrderId: this.recordId,
                PricebookEntryId: item.pricebookEntryId,
                Quantity: item.quantity,
                UnitPrice: item.price,
                RR_Parts_Category__c: item.RR_Parts_Category__c,
                Consequential_Parts__c: item.isChild ? 'Yes' : 'No',
                Sequence_Number__c: idToSequence[item.id],
                Parent_Sequence_Number__c: item.parentId ? idToSequence[item.parentId] : null,
                Replacement_Type__c: item.isChild ? 'Consequential' : item.Replacement_Type__c,
                Failure_Code__c: item.Failure_Code__c,
                TFR_Required__c: item.TFR_Required__c,
                RR_Product__c: item.productId,
                Warranty_Prior__c: isAddWP ? this.warrantyId : null,
                Post_Vin_cutt_off__c: item.Post_Vin_cutt_off__c,
                ...(!item.isChild && {
                    Electrical_Value__c: item.Electrical_Value__c,
                    Part_Description__c: item.Part_Description__c
                })
            };
        });
    }

    resetForm() {
        this.itemList = [];
        this.addParentRow();
    }

    // UTILITY METHODS
    showError(index, message) {
        this.itemList[index] = {
            ...this.itemList[index],
            hasError: true,
            errorMessage: message
        };
        this.updateErrorStatus();
    }

    clearError(index) {
        this.itemList[index] = {
            ...this.itemList[index],
            hasError: false,
            errorMessage: ''
        };
        this.updateErrorStatus();
    }

    updateErrorStatus() {
        this.hasErrorInList = this.itemList.some(item => item.hasError);
    }

    showToast(title, message, variant) {
        this.handlealer(title, message, variant)
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handlealer(title, message, variant) {
        LightningAlert.open({
            message: message,
            theme: variant, // a red theme intended for error states
            label: title, // this is the header text
        });
    }

    handleError(message, error) {
        console.error(message, error);
        this.showToast('Error', `${message}: ${error.body?.message || error.message}`, 'error');
    }

    async fetchWarranty() {
        try {
            const result = await getWarrantyForJobCard({ workOrderId: this.recordId });
            this.warrantyId = result?.Id;
        }
        catch (error) {
            this.handleError('Error  loading warranty information', error);
        }
    }

    // fetchWarranty() {
    //      ({ workOrderId: this.recordId })
    //         .then(result => {
    //             this.warrantyId = result.Id;
    //             console.log('---result',result)
    //             if(result.Status__c != 'Sumbit for Approval'){
    //                 this.showAll = true;
    //             }else{
    //                 this.showAll = false;
    //             }

    //             console.log('Fetched Warranty ID: ', this.warrantyId);
    //         })
    //         .catch(error => {
    //             console.error('Error fetching Warranty ID:', error);
    //         });
    // }

    toggleTemplates() {
        this.showAll = !this.showAll;
    }

    applyDuplicateRules(list, rules) {
        debugger;
        const results = {};
        for (const rule of rules) {
            const keyName = rule.fields.join("_");
            results[keyName] = this.findDuplicatesByFields(list, rule.fields);
        }

        return results;
    }

    findDuplicatesByFields(list, fields) {
        debugger;
        const seen = new Set();
        const duplicates = [];

        for (const item of list) {
            const key = fields.map(f => item[f]).join("|"); // unique key
            if (seen.has(key)) {
                duplicates.push(item);
            } else {
                seen.add(key);
            }
        }
        return duplicates;
    }

    // console.log(applyDuplicateRules(records, rules));


    VeripartWithActionWithPlan(workOrderId) {
        debugger;
        VeripartWithActionWithPlanApex({ workOrderId: workOrderId })
            .then(data => {
                console.log(`actionplans data ${JSON.stringify(data)}`)
                this.ActionPlanProducts = data.RequiredProducts;
                this.ActionPlanlabours = data.RequiredLabours;
            })
            .catch(error => {
                console.error('Error in VeripartWithActionWithPlan:', error);
            });
    }

    checkActionPlansWithProducts(productId) {
        debugger;
        const isProductfoundInAP = this.ActionPlanProducts.map(item => item.Product__c == productId);
        return isProductfoundInAP;
    }
}