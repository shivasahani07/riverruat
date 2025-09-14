import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFailureCodes from '@salesforce/apex/TFRController.getFailureCodes';
import deleteFailureCode from '@salesforce/apex/TFRController.deleteFailureCode';

export default class FailureCodeTable extends NavigationMixin(LightningElement) {
  @track failureCodes = [];
  @track error;
  @track OrignalData = [];
  @track fialureCodeValue = '';
  @track productCodeValue = '';
  @track VINCuttoffValue = '';
  @track isShowModalPopup = false;

  @track componentConstructor = null;
  @track childProps = {};
  @track isLoading = true;
  @track hasError = false;
  @track errorMessage = '';
  @track childProps = {

  }

  @track page = 1;          // current page
  @track pageSize = 100;     // records per page
  @track totalPages = 0;    // total number of pages
  @track paginatedData = []; // records shown in current page

  get pageSizeOptions() {
    return [
        { label: '5', value: 5 },
        { label: '10', value: 10 },
        { label: '20', value: 20 },
        { label: '50', value: 50 }
    ];
  }

  componentName = 'addFailureCodeLwcComp';

  @wire(getFailureCodes)
  wiredCodes({ data, error }) {
    if (data) {
      this.failureCodes = data.map(fc => {
        const isActive = !!fc.Is_Active__c;
        const vinActive = !!fc.VIN_Cut_off__r?.Is_Active__c;
        return {
          Id: fc.Id,
          Name: fc.Name,
          BatchSize: fc.Batch_Size__c,
          SampleCollected: fc.Sample_Collected__c,
          IsActive: isActive,
          ProductName: fc.TFR_Part_Effect__r?.Product__r?.Name || '',
          ProductCode: fc.TFR_Part_Effect__r?.Product__r?.ProductCode || '',
          VinStart: fc.VIN_Cut_off__r?.VIN_Start__c || '',
          VinCutOffActive: vinActive,
          // precomputed classes + labels for template (no ternary in HTML)
          isActiveClass: `status ${isActive ? 'active' : 'inactive'}`,
          isActiveLabel: isActive ? 'Active' : 'Inactive',
          vinActiveClass: `status ${vinActive ? 'active' : 'inactive'}`,
          vinActiveLabel: vinActive ? 'Active' : 'Inactive',
          CreatedBy: fc.CreatedBy.Name,
          FCxPC: `${fc.Name}` + '-' + `${fc.TFR_Part_Effect__r?.Product__r?.Name || ''}`,
          CreatedDate: fc.CreatedDate,
          Combination: fc.FPV_Validation__c
        };
      });
      this.error = undefined;
      this.OrignalData = this.failureCodes;
      this.updatePagination();
      console.log('OrignalData--', this.OrignalData)
      console.log('failureCodes--', this.failureCodes)
    } else if (error) {
      this.error = error;
      this.failureCodes = [];
    }
  }

  get hasData() {
    return this.failureCodes.length > 0;
  }

  handleView(event) {
    debugger;
    const recordId = event.target.dataset.id;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName: 'Failure_Code__c', actionName: 'view' }
    });
  }

  handleEdit(event) {
    debugger;
    const recordId = event.target.dataset.id;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId, objectApiName: 'Failure_Code__c', actionName: 'edit' }
    });
  }

  handleDelete(event) {
    debugger;
    const recordId = event.target.dataset.id;
    deleteFailureCode({ recordId })
      .then(() => {
        this.showToast('Deleted', 'Record deleted successfully', 'success');
        return getFailureCodes(); // quick refresh
      })
      .then(data => {
        this.wiredCodes({ data }); // reuse mapper
      })
      .catch(err => this.showToast('Error', err?.body?.message || 'Delete failed', 'error'));
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // filter data as per inputs
  filterOnchage(event) {
    debugger;
    let name = event.target.name;
    let value = event.target.value;
    let smallvalue = value.toLowerCase();

    if (name === "productCode") {
      this.failureCodes = this.OrignalData.filter(item =>
        item.ProductCode && item.ProductCode.toLowerCase().includes(smallvalue)
      );
    } else if (name === "failureCode") {
      this.failureCodes = this.OrignalData.filter(item =>
        item.Name && item.Name.toLowerCase().includes(smallvalue)
      );
    } else if (name === "VINCutoff") {
      this.failureCodes = this.OrignalData.filter(item =>
        item.VinStart && item.VinStart.toLowerCase().includes(smallvalue)
      );
    }
  }

  // keep track of filter values
  // filters = {
  //   productCode: '',
  //   failureCode: '',
  //   VINCutoff: ''
  // };

  // filterOnchage(event) {
  //   let name = event.target.name;
  //   let value = event.target.value ? event.target.value.toLowerCase() : '';

  //   // update the filter value
  //   this.filters[name] = value;

  //   // filter from original dataset
  //   this.failureCodes = this.OrignalData.filter(item => {
  //     const matchProduct =
  //       !this.filters.productCode ||
  //       (item.ProductCode && item.ProductCode.toLowerCase().includes(this.filters.productCode));

  //     const matchFailure =
  //       !this.filters.failureCode ||
  //       (item.Name && item.Name.toLowerCase().includes(this.filters.failureCode));

  //     const matchVIN =
  //       !this.filters.VINCutoff ||
  //       (item.VinStart && item.VinStart.toLowerCase().includes(this.filters.VINCutoff));

  //     return matchProduct && matchFailure && matchVIN;
  //   });
  // }


  // clearfiter function

  clearfilter() {
    debugger;
    this.fialureCodeValue = null;
    this.productCodeValue = null;
    this.VINCuttoffValue = null;
  }

  addFailureCode() {
    debugger;
    this.isShowModalPopup = true
    this.loadComponent(this.componentName);

  }

  loadComponent(componentName) {
    debugger;
    import(`c/${componentName}`)
      .then(({ default: ctor }) => {
        this.componentConstructor = ctor;
        this.isLoading = false;
      })
      .catch((err) => {
        this.hasError = true;
        this.errorMessage = `Component '${componentName}' could not be loaded.`;
        this.isLoading = false;
        console.error('Error importing component', err);
      });
  }

  hideModalBox() {
    this.isShowModalPopup = false;
  }

  // Update paginated data whenever failureCodes changes
  updatePagination() {
      if (!this.failureCodes) {
          this.paginatedData = [];
          return;
      }
      this.totalPages = Math.ceil(this.failureCodes.length / this.pageSize);

      // slice array for current page
      const start = (this.page - 1) * this.pageSize;
      const end = this.page * this.pageSize;
      this.paginatedData = this.failureCodes.slice(start, end);
  }

  handleNext() {
      if (this.page < this.totalPages) {
          this.page++;
          this.updatePagination();
      }
  }

  handlePrevious() {
      if (this.page > 1) {
          this.page--;
          this.updatePagination();
      }
  }

  handlePageSizeChange(event) {
      this.pageSize = parseInt(event.target.value, 10);
      this.page = 1; // reset to first page
      this.updatePagination();
  }

  // Disable "Previous" button on First Page
  get disablePreviousBtn() {
      return this.page <= 1; 
  }

  // Disable "Next" button on Last Page
  get disableNextBtn() {
      return this.page >= this.totalPages; 
  }

}