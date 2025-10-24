import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFailureCodes from '@salesforce/apex/TFRManagement.getFailureCodes';
import deleteFailureCode from '@salesforce/apex/TFRManagement.deleteFailureCode';
import { refreshApex } from '@salesforce/apex';


export default class FailureCodeTable extends NavigationMixin(LightningElement) {
    @track failureCodes = [];
    @track error;
    @track OrignalData = [];
    @track isShowModalPopup = false;
    @track componentConstructor = null;
    @track childProps = {};
    @track isLoading = true;
    @track refreshResultData;;
    @track pageData = [];
    @track totalRecords = 0;
    
    // Filters
    @track filters = {
        failureCode: '',
        codeValue: '',
        VINCutoff: '',
        typeFilter: '',
        recordId:''
    };
    
    // Type options for filter
    typeOptions = [
        { label: 'All Types', value: '' },
        { label: 'Part', value: 'Part' },
        { label: 'Labour', value: 'Labour' }
    ];

    // Component names
    productComponentName = 'AddFailureCodeLwcComp';
    labourComponentName = 'AddLabourFailureCodeLwcComp';
    nextButtonComponent='TfrLabourEffectManager';

    @wire(getFailureCodes)
    wiredCodes(result) {
         this.refreshResultData = result;
         let  {data,error} = result;
        if (data) {
          debugger
            this.failureCodes = data.map(fc => {
                const isActive = !!fc.Is_Active__c;
                const vinActive = !!fc.VIN_Cut_off__r?.Is_Active__c;
                
                // Determine type and causal information
                let type, causalName, causalCode;
                
                if (fc.TFR_Part_Effect__c) {
                    type = 'Part';
                    causalName = fc.TFR_Part_Effect__r?.Product__r?.Name || '';
                    causalCode = fc.TFR_Part_Effect__r?.Product__r?.ProductCode || '';
                } else if (fc.TFR_Labour_Effect__c) {
                    type = 'Labour';
                    causalName = fc.TFR_Labour_Effect__r?.Code_Set__r?.Name || '';
                    causalCode = fc.TFR_Labour_Effect__r?.Code_Set__r?.Code || '';
                }
                
                return {
                    Id: fc.Id,
                    Name: fc.Name,
                    Type: type,
                    BatchSize: fc.Batch_Size__c,
                    SampleCollected: fc.Sample_Collected__c,
                    IsActive: isActive,
                    CausalName: causalName,
                    CausalCode: causalCode,
                    VinStart: fc.VIN_Cut_off__r?.VIN_Start__c || '',
                    VinCutOffActive: vinActive,
                    isActiveClass: `status ${isActive ? 'active' : 'inactive'}`,
                    isActiveLabel: isActive ? 'Active' : 'Inactive',
                    vinActiveClass: `status ${vinActive ? 'active' : 'inactive'}`,
                    vinActiveLabel: vinActive ? 'Yes' : 'NO',
                    CreatedBy: fc.CreatedBy?.Name || '',
                    CreatedDate: fc.CreatedDate,
                    Combination: fc.FPV_Validation__c
                };
            });
            this.OrignalData = this.failureCodes;
            this.error = undefined;
            this.totalRecords = this.failureCodes.length;
        } else if (error) {
            this.error = error;
            this.failureCodes = [];
        }
        this.isLoading = false;
    }

    get hasData() {
        return this.failureCodes.length > 0;
    }

    handleView(event) {
        const recordId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName: 'Failure_Code__c', actionName: 'view' }
        });
    }

    handleEdit(event) {
        const recordId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName: 'Failure_Code__c', actionName: 'edit' }
        });
    }

    apexRefresh(istrue){
        debugger;
        this.showToast('updated', 'data refreshed', 'success');
        return refreshApex(this.refreshResultData);
    }

    handleDelete(event) {
        const recordId = event.target.dataset.id;
        deleteFailureCode({ recordId })
            .then(() => {
                this.showToast('Deleted', 'Record deleted successfully', 'success');
                // Refresh data
                return getFailureCodes();
            })
            .then(data => {
                this.wiredCodes({ data });
            })
            .catch(err => this.showToast('Error', err?.body?.message || 'Delete failed', 'error'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    filterOnchage(event) {
        debugger;
        const name = event.target.name;
        const value = event.target.value;
        
        // Update filters
        this.filters = {
            ...this.filters,
            [name]: value
        };
        
        // Apply all filters
        this.applyFilters();
    }
    
    applyFilters() {
        debugger;
        this.pageData = this.OrignalData.filter(item => {  
            const failureCodeMatch = !this.filters.failureCode || 
                (item.Name && item.Name.toLowerCase().includes(this.filters.failureCode.toLowerCase()));
            
            const codeMatch = !this.filters.codeValue || 
                (item.CausalCode && item.CausalCode.toLowerCase().includes(this.filters.codeValue.toLowerCase()));
            
            const vinMatch = !this.filters.VINCutoff || 
                (item.VinStart && item.VinStart.toLowerCase().includes(this.filters.VINCutoff.toLowerCase()));
            
            const typeMatch = !this.filters.typeFilter || 
                (item.Type && item.Type === this.filters.typeFilter);
            
            return failureCodeMatch && codeMatch && vinMatch && typeMatch;
        });
    }

    handleAddFailureCode(event) {
      debugger;
        const type = event.detail.value;
        this.isShowModalPopup = true;
        debugger;
        if (type === 'product') {
            this.loadComponent(this.productComponentName);
        } else if (type === 'labour') {
            this.loadComponent(this.labourComponentName);
        }
    }

    loadComponent(componentName) {
      debugger;
        import(`c/${componentName}`)
            .then(({ default: ctor }) => {
                this.componentConstructor = ctor;
            })
            .catch((err) => {
                this.showToast('Error', `Component '${componentName}' could not be loaded.`, 'error');
                console.error('Error importing component', err);
            });
    }

    hideModalBox() {
        this.isShowModalPopup = false;
        // Refresh data after modal is closed
        getFailureCodes()
            .then(data => {
                this.wiredCodes({ data });
            })
            .catch(error => {
                console.error('Error refreshing data', error);
            });
    }

    addLabourCode(event){
        debugger;
        const recordId = event.target.dataset.id;
         this.isShowModalPopup = true;
         this.childProps.recordId=recordId;
        this.loadComponent('TfrLabourEffectManager');

    }

    handlePageChange(event) {
        debugger;
        this.pageData = event.detail.pageRecords;
    }
}