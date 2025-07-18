import { LightningElement, api } from 'lwc';
import processVINs from '@salesforce/apex/FieldFixActionPlanController.processVINs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import SHEETJS from '@salesforce/resourceUrl/SHEETJS';
import { loadScript } from 'lightning/platformResourceLoader';

export default class FieldFixVinUploader extends LightningElement {
    @api recordId;
    vinInput = '';
    message = '';

        renderedCallback() {
        if (this.sheetJsInitialized) return;
        this.sheetJsInitialized = true;

        loadScript(this, SHEETJS)
            .then(() => {
                console.log('SheetJS loaded successfully');
            })
            .catch(error => {
                console.error('SheetJS load failed', error);
            });
    }

    handleVINChange(event) { debugger; this.vinInput = event.target.value; }

    async handleCreate() {
        debugger;
        this.message = '';

        if (!this.vinInput || !this.recordId) {
            this.message = 'Please enter VINs and ensure Field Fix ID is available.';
            return;
        }

        try {
            const result = await processVINs({
                vinCSV: this.vinInput,
                fieldFixId: this.recordId
            });

            this.message = result;

            let toastVariant = 'success';
            if (result.startsWith('0 Action Plans')) {
                toastVariant = 'error';
            } else if (result.includes('Skipped VINs')) {
                toastVariant = 'warning';
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: toastVariant === 'success' ? 'Success' :
                        toastVariant === 'warning' ? 'Partial Success' : 'No Action Plans Created',
                    message: result,
                    variant: toastVariant
                })
            );

            if (toastVariant === 'success') {
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        } catch (error) {
            console.error(error);
            this.message = 'Error occurred while creating action plans.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.message,
                    variant: 'error'
                })
            );
        }
    }


    // handleCSVFileChange(event) {
    //     debugger;
    //     const file = event.target.files[0];
    //     if (file) {
    //         const reader = new FileReader();
    //         reader.onload = () => {
    //             const text = reader.result;
    //             this.vinInput = this.extractVINsFromCSV(text);
    //         }
    //         reader.readAsText(file);
    //     }
    // }
    handleCSVFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        const fileName = file.name.toLowerCase();
        const reader = new FileReader();

        if (fileName.endsWith('.csv')) {
            reader.onload = () => {
                const text = reader.result;
                this.vinInput = this.extractVINsFromCSV(text);
            };
            reader.readAsText(file);
        } else if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
            reader.onload = (e) => {
                const data = new Uint8Array(e.target.result);
                const workbook = window.XLSX.read(data, { type: 'array' });

                const sheetName = workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                const json = window.XLSX.utils.sheet_to_json(sheet, { header: 1 });

                let vins = [];
                json.forEach(row => {
                    row.forEach(cell => {
                        const value = (cell || '').toString().trim();
                        if (value) vins.push(value);
                    });
                });

                this.vinInput = vins.join('\n');
            };
            reader.readAsArrayBuffer(file);
        } else {
            this.showToast('Error', 'Unsupported file type. Upload .csv or .xlsx only.', 'error');
        }
    }

    extractVINsFromCSV(csvText) {
        return csvText
            .split(/[\n\r,]+/)
            .map(v => v.trim())
            .filter(v => v.length > 0)
            .join('\n');
    }
}