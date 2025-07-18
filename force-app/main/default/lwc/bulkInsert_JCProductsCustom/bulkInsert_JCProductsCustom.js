import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAvailableQuantity from '@salesforce/apex/WorkOrderLineItemController.getAvailableQuantity';
import getPricebookEntry from '@salesforce/apex/WorkOrderLineItemController.getPricebookEntry';
import createWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.createWorkOrderLineItems';
import getRelatedWorkOrderLineItems from '@salesforce/apex/WorkOrderLineItemController.getRelatedWorkOrderLineItems';
import getWarrantyForJobCard from '@salesforce/apex/WorkOrderLineItemController.getWarrantyForJobCard';
import verifyExistingTFR from '@salesforce/apex/TFRController.checkTFRValidation';

import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

const STATUS_FIELD = 'WorkOrder.Status';

export default class BulkInsertJCProductsCustom extends NavigationMixin(LightningElement) {
    @api recordId = '0WOF4000001HKe4OAG'
    @track itemList = [];
    @track existingWorkOrderLineItems = [];
    @track warrantyId;
    @track showAll = false;
    @track hasErrorInList = false;
    keyIndex = 0;
    refreshResultData;
    @track isLoading = false;
    @track currentVinNo;

    @track expandedRows = [];
    @track treeColumns = [
        {
            type: 'text',
            fieldName: 'displayName',
            label: 'Product',
            initialWidth: 300,
            cellAttributes: {
                class: { fieldName: 'rowClass' }
            }
        },
        {
            label: 'Part No',
            fieldName: 'partUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'displayName' },
                target: '_blank'
            },
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        // {
        //     type: 'url',
        //     fieldName: 'displayName',
        //     label: 'Product',
        //     // initialWidth: 300,
        //     typeAttributes: {
        //         label: { fieldName: 'displayProduct' },
        //         target: '_blank'
        //     },
        //     cellAttributes: { class: { fieldName: 'rowClass' } }
        // },
        {
            type: 'text',
            fieldName: 'ProductCode',
            label: 'Part Code',
            // initialWidth: 120
        },
        {
            type: 'number',
            fieldName: 'Quantity',
            label: 'Quantity',
            initialWidth: 120
        },
        {
            type: 'text',
            fieldName: 'RR_Parts_Category__c',
            label: 'Parts Category',
            // initialWidth: 150
        },
        {
            type: 'text',
            fieldName: 'Status',
            label: 'Status',
            // initialWidth: 120
        },
        // {
        //     type: 'action',
        //     typeAttributes: { 
        //         rowActions: this.getRowActions 
        //     }
        // }
    ];

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
        { label: 'Non-Causal', value: 'Non-Causal' }
    ];

    columns = [
        {
            label: 'Part No',
            fieldName: 'partUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'displayName' },
                target: '_blank'
            },
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Product',
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'displayProduct' },
                target: '_blank'
            },
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Part Code',
            fieldName: 'ProductCode',
            type: 'text',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Quantity',
            fieldName: 'Quantity',
            type: 'number',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Parts Category',
            fieldName: 'RR_Parts_Category__c',
            type: 'text',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Type',
            fieldName: 'Consequential_Part__c',
            type: 'text',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        },
        {
            label: 'Parent Product',
            fieldName: 'Parent_Product_Name__c',
            type: 'text',
            cellAttributes: { class: { fieldName: 'rowClass' } }
        }
    ];

    getCurrentExpandedRows() {
        const treegrid = this.template.querySelector('.lgc-example-treegrid');
        this.expandedRows = treegrid.expandedRows().toString();
    }

    connectedCallback() {
        this.fetchWarranty();
        this.addParentRow();
    }

    @wire(getRecord, { recordId: "$recordId", fields: [STATUS_FIELD] })
    wiredWorkOrder({ error, data }) {
        if (data) {
            const status = data.fields.Status.value;
            const blockedStatuses = new Set([
                'Ready for Delivery',
                'Submit For Approval',
                'Cancellation Requested',
                'Canceled',
                'Completed'
            ]);
            const editableStatuses = new Set([
                'New',
                'In Progress',
                'Re work'
            ]);

            this.showAll = editableStatuses.has(status) && !blockedStatuses.has(status);
        }
        if (error) {
            console.error('Error occurred:', error);
            this.showToast('Error', 'Error loading work order status', 'error');
        }
    }

    @wire(getRelatedWorkOrderLineItems, { workOrderId: '$recordId' })
    wiredWorkPlans(result) {
        this.refreshResultData = result;
        if (result.data) {
            this.processExistingItems(result.data);
            this.currentVinNo = result.data[0].WorkOrder.Vehicle_Identification_Number__c;
        } else if (result.error) {
            console.error('Error fetching Work Plans:', result.error);
            this.showToast('Error', 'Error loading existing line items', 'error');
        }
    }

    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
        doneCallback(actions);
    }


    processExistingItems(rawItems) {
        // Deep clone to avoid mutating @wire proxy objects
        const items = JSON.parse(JSON.stringify(rawItems));

        const itemMap = new Map();

        // Step 1: Build a map of all items
        items.forEach(item => {
            item._children = [];
            item.displayName = item.PricebookEntry?.Product2?.Name || item.Name;
            item.ProductCode = item.PricebookEntry?.Product2?.ProductCode || '';
            item.rowClass = item.Part__c ? 'slds-text-color_weak' : '';
            item.partUrl = `/${item.Id}`;
            item.productUrl = item.PricebookEntry?.Product2Id ? `/${item.PricebookEntry.Product2Id}` : '';
            itemMap.set(item.Id, item);
        });

        const rootItems = [];

        // Step 2: Build hierarchy
        items.forEach(item => {
            if (item.Part__c && itemMap.has(item.Part__c)) {
                itemMap.get(item.Part__c)._children.push(item);
            } else {
                rootItems.push(item);
            }
        });

        // Step 3: Assign to reactive variables
        this.existingWorkOrderLineItems = rootItems;
        this.expandedRows = rootItems.map(item => item.Id);
        console.log('expandedRows data:', (JSON.stringify(this.expandedRows)));
        console.log('TreeGrid data:', (JSON.stringify(this.existingWorkOrderLineItems)));
    }





    async fetchWarranty() {
        try {
            const result = await getWarrantyForJobCard({ workOrderId: this.recordId });
            this.warrantyId = result.Id;
        } catch (error) {
            console.error('Error fetching Warranty ID:', error);
            this.showToast('Error', 'Error loading warranty information', 'error');
        }
    }

    // PARENT-CHILD ROW MANAGEMENT

    addParentRow() {
        debugger;
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
        debugger;
        this.keyIndex++;
        const parentId = this.itemList[parentIndex].id;
        const childRow = this.createRowObject(this.keyIndex, true, parentId);

        // Find the last child of this parent
        const lastChildIndex = this.findLastChildIndex(parentId);

        // Insert after the last child or after parent if no children exist
        const insertPosition = lastChildIndex !== -1 ? lastChildIndex + 1 : parentIndex + 1;

        this.itemList.splice(insertPosition, 0, childRow);
        this.itemList = [...this.itemList]; // Force re-render

        // Update parent's hasChildren flag
        this.itemList[parentIndex].hasChildren = true;
    }

    findLastChildIndex(parentId) {
        debugger;
        let lastIndex = -1;
        this.itemList.forEach((item, index) => {
            if (item.parentId === parentId) {
                lastIndex = index;
            }
        });
        return lastIndex;
    }

    createRowObject(id, isChild = false, parentId = null) {
        debugger;
        return {
            id: id,
            productId: '',
            quantity: 1,
            partsCategory: '',
            replacementType: '',
            electricalValue: '',
            partDescription: '',
            showAdditionalFields: false,
            showVideofield: false,
            hasError: false,
            errorMessage: '',
            isChild: isChild,
            parentId: parentId,
            hasChildren: false,
            cssClass: this.getRowClass(isChild),
            sequence: this.getNextSequenceNumber(isChild, parentId),
            pricebookEntryId: null,
            price: 0,
            availableQuantity: 0,
            productCode: '',

            TFR_Required__c: false,
            Replacement_Type__c: '',
            filter: {
                criteria: [
                    {
                        fieldPath: '',
                        operator: '',
                        value: ''
                    },
                    {
                        fieldPath: '',
                        operator: '',
                        value: ''
                    }
                ]
            },
        };
    }

    getRowClass(isChild) {
        debugger;
        const baseClass = 'slds-box slds-m-bottom_medium slds-p-around_medium';
        return isChild ? `${baseClass} slds-theme_shade` : baseClass;
    }

    getNextSequenceNumber(isChild, parentId) {
        debugger;
        if (!isChild) {
            // For parent rows: 1, 2, 3...
            return this.itemList.filter(item => !item.isChild).length + 1;
        } else {
            // For child rows: 1.1, 1.2, 2.1...
            const parent = this.itemList.find(item => item.id === parentId);
            if (parent) {
                const childCount = this.itemList.filter(item => item.parentId === parentId).length;
                return `${parent.sequence}.${childCount + 1}`;
            }
            return '0.0';
        }
    }

    removeRow(event) {
        debugger;
        const index = parseInt(event.target.dataset.id, 10);
        const item = this.itemList[index];

        if (item.isChild) {
            // Remove just this child
            this.itemList = this.itemList.filter((_, i) => i !== index);

            // Check if parent has any remaining children
            const parentIndex = this.itemList.findIndex(i => i.id === item.parentId);
            if (parentIndex !== -1) {
                const hasChildren = this.itemList.some(i => i.parentId === this.itemList[parentIndex].id);
                this.itemList[parentIndex].hasChildren = hasChildren;
            }
        } else if (item.hasChildren) {
            // Confirm before removing parent with children
            if (confirm('This product has consequential products. Remove all?')) {
                this.removeParentAndChildren(index);
            }
        } else {
            // Regular parent row with no children
            this.itemList = this.itemList.filter((_, i) => i !== index);
        }
    }

    removeParentAndChildren(parentIndex) {
        debugger;
        const parentId = this.itemList[parentIndex].id;
        this.itemList = this.itemList.filter(item =>
            item.id !== parentId && item.parentId !== parentId
        );
    }

    // FIELD HANDLERS

    handleProductChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const productId = event.detail.recordId;
        this.itemList[index].productId = productId;

        if (productId) {
            this.fetchProductDetails(index, productId);

        } else {
            this.clearProductDetails(index);
        }
    }

    fetchProductDetails2(index, productId) {
        debugger;
        getPricebookEntry({ productId: productId })
            .then(result => {
                this.accounts = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.accounts = undefined;
            })
    }
    setFailureCodeFilterasPerProduct(index, vinCutoff) {
        debugger;
        const productId = this.itemList[index].productId;

        // Always apply the Is_Active filter
        this.itemList[index].filter.criteria[0] = {
            fieldPath: 'Is_Active__c',
            operator: 'eq',
            value: true
        };

        // Now conditionally add the second filter
        if (vinCutoff != null || vinCutoff !== undefined) {
            this.itemList[index].filter.criteria[1] = {
                fieldPath: 'VIN_Cut_off__c',
                operator: 'eq',
                value: vinCutoff
            };
        } else {
            this.itemList[index].filter.criteria[1] = {
                fieldPath: 'TFR_Part_Effect__c',
                operator: 'eq',
                value: productId
            };
        }
    }


    filter = {
        criteria: [
            {
                fieldPath: 'VIN_Cut_off__c',
                operator: 'eq',
                value: 'a36Bh000000ghN7IAI'
            }
        ]
    };


    async fetchProductDetails(index, productId) {
        debugger;
        try {
            const prepareData = await getPricebookEntry({ productId: productId });
            const pricebookEntry = prepareData.returnPriceBook;
            const r_causalParts = prepareData?.EffectedParts;
            const vinuctoffId = prepareData?.EffectedParts?.TFR__c;
            this.itemList[index].pricebookEntryId = pricebookEntry.Id;
            this.itemList[index].price = pricebookEntry.UnitPrice;
            this.itemList[index].productCode = pricebookEntry.Product2?.ProductCode;
            this.itemList[index].TFR_Required__c = (r_causalParts != undefined || r_causalParts != null);
            this.itemList[index].isFailureCodeVisible = (r_causalParts != undefined || r_causalParts != null);
            const availableQuantity = await getAvailableQuantity({
                productId: productId,
                workOrderId: this.recordId
            });

            this.setFailureCodeFilterasPerProduct(index, vinuctoffId);

            this.itemList[index].availableQuantity = availableQuantity;
            this.validateQuantity(index);

        } catch (error) {
            this.showError(index, 'Error fetching product details: ' + error.body.message);
        }
    }

    clearProductDetails(index) {
        this.itemList[index].pricebookEntryId = null;
        this.itemList[index].price = 0;
        this.itemList[index].productCode = '';
        this.itemList[index].availableQuantity = 0;
        this.clearError(index);
    }

    handleQuantityChange(event) {
        const index = event.target.dataset.id;
        const quantity = event.target.value;
        this.itemList[index].quantity = quantity;
        this.validateQuantity(index);
    }

    validateQuantity(index) {
        debugger;
        const item = this.itemList[index];
        if (item.quantity <= 0) {
            this.showError(index, 'Quantity must be greater than 0');
        } else if (item.quantity > item.availableQuantity) {
            this.showError(index, `Quantity exceeds available stock (${item.availableQuantity})`);
        } else {
            this.clearError(index);
        }
    }

    handlePicklistChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const fieldName = event.target.dataset.fieldname;
        const value = event.detail.value;

        this.itemList[index][fieldName] = value;

        if (fieldName === 'RR_Parts_Category__c') {
            this.itemList[index].showAdditionalFields = value !== 'Paid';
            this.itemList[index].isElectricalValueRequired = false;
            this.itemList[index].partsCategory = value;

        }

        if (fieldName === 'Replacement_Type__c') {
            this.itemList[index].isElectricalValueRequired = value === 'Causal';
            this.itemList[index].isFailureCodeVisible = this.itemList[index].TFR_Required__c;
            if (this.itemList[index].isFailureCodeVisible) {
                this.itemList[index].Replacement_Type__c = 'Causal'
            }

        }
    }

    handleFailureCodeChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const failurecode = event.detail.recordId;
        const currentItem = this.itemList[index];
        this.itemList[index].Failure_Code__c = failurecode;
        // this.itemList[index].TFR_Required__c=true;
        const vin = this.currentVinNo;
        this.CheckisTFRApplicable(vin, failurecode, index)

    }


    async CheckisTFRApplicable(VINno, FailureCodeId, index) {
        try {
            debugger;
            const returndata = await verifyExistingTFR({ VINno: VINno, FailureCodeId: FailureCodeId });
            // Assuming returndata is Boolean or has a flag like isApplicable
            if (returndata.isTFRApplicable) {
                this.itemList[index].TFR_Required__c = true;
            } else {
                this.itemList[index].TFR_Required__c = false;
            }

        } catch (error) {
            console.error('Error in CheckisTFRApplicable:', error);
            this.itemList[index].TFR_Required__c = false; // optionally set false on failure
        }
    }

    handleInputChange(event) {
        debugger;
        const index = event.target.dataset.id;
        const fieldName = event.target.dataset.fieldname;
        const value = event.target.value;
        this.itemList[index][fieldName] = value;
    }

    // FORM SUBMISSION

    async handleSubmit() {
        debugger;
        // Validate all 
        this.isLoading = true;
        let isValid = true;
        console.log('this.itemList----', JSON.stringify(this.itemList));
        this.itemList.forEach((item, index) => {
            if (!item.productId) {
                this.showError(index, 'Please select a product');
                isValid = false;
            }

            if (item.quantity <= 0 || item.quantity > item.availableQuantity) {
                this.showError(index, 'Invalid quantity');
                isValid = false;
            }

            if (item.isChild && !item.parentId) {
                this.showError(index, 'Consequential product missing parent');
                isValid = false;
            }
        });

        if (!isValid) {
            this.showToast('Error', 'Please fix all errors before submitting', 'error');
            this.isLoading = false;
            return;
        }

        try {
            debugger;
            const lineItems = this.prepareLineItems();
            console.log('lineItems----', JSON.stringify(lineItems));
            await createWorkOrderLineItems({ lineItems: lineItems });

            this.showToast('Success', 'Products added successfully', 'success');
            await refreshApex(this.refreshResultData);
            this.resetForm();
            this.isLoading = false;

        } catch (error) {
            this.showToast('Error', 'Failed to add products: ' + error.body.message, 'error');
            this.isLoading = false;
        }
    }

    prepareLineItems() {
        debugger;
        // Create a list with parent items first, then children
        const sortedItems = [];
        const parentItems = this.itemList.filter(item => !item.isChild);
        const childItems = this.itemList.filter(item => item.isChild);

        // Add parents first, then children
        sortedItems.push(...parentItems);
        sortedItems.push(...childItems);

        // Create a mapping of original IDs to sequence numbers
        const idToSequence = {};
        sortedItems.forEach((item, index) => {
            idToSequence[item.id] = index + 1; // 1-based sequence
        });

        return sortedItems.map(item => {
            const lineItem = {
                WorkOrderId: this.recordId,
                Warranty_Prior__c: this.warrantyId,
                PricebookEntryId: item.pricebookEntryId,
                Quantity: item.quantity,
                UnitPrice: item.price,
                RR_Parts_Category__c: item.partsCategory,
                Consequential_Parts__c: item.isChild ? 'Yes' : 'No',
                // Store sequence info for Apex to process
                Sequence_Number__c: idToSequence[item.id],
                Parent_Sequence_Number__c: item.parentId ? idToSequence[item.parentId] : null,
                Replacement_Type__c: item.Replacement_Type__c,
                Failure_Code__c: item.Failure_Code__c,
                TFR_Required__c: item.TFR_Required__c
            };

            if (!item.isChild) {
                lineItem.Replacement_Type__c = item.Replacement_Type__c;
                lineItem.Electrical_Value__c = item.Electrical_Value__c;
                lineItem.Part_Description__c = item.Part_Description__c;
            }

            return lineItem;
        });
    }

    resetForm() {
        this.itemList = [];
        this.addParentRow();
    }

    // UTILITY METHODS

    showError(index, message) {
        this.itemList[index].hasError = true;
        this.itemList[index].errorMessage = message;
        this.updateErrorStatus();
    }

    clearError(index) {
        this.itemList[index].hasError = false;
        this.itemList[index].errorMessage = '';
        this.updateErrorStatus();
    }

    updateErrorStatus() {
        this.hasErrorInList = this.itemList.some(item => item.hasError);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    toggleTemplates() {
        this.showAll = !this.showAll;
    }

    filter = {
        criteria: [
            {
                fieldPath: 'LeadSource',
                operator: 'eq',
                value: 'Web'
            }
        ]
    };
}