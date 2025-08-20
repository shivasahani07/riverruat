import { LightningElement,track,api} from 'lwc';
//import getDocumentsForRecord from '@salesforce/apex/PreviewFileHandler.getDocumentsForRecord';
export default class Lwcpreviewfile extends LightningElement {

    @track showPDF;
    @track pdfUrl;
    @api recordId

    connectedCallback() {
        debugger;
       //this.getViewPreviewFile();
    }

getViewPreviewFile(){
    debugger;
    getDocumentsForRecord({OpportunityId : this.recordId})
    .then(result =>{
        if(result){
        this.showPDF = true;
         //this.blobData =result;
         if(result){
             // Create a Blob from base64-encoded string
            const pdfBlob = this.base64ToBlob(result);
            // Generate a Blob URL for the PDF
            this.pdfUrl = URL.createObjectURL(pdfBlob);
         }
        }
    })
    .catch(error =>{
     this.error = error;
    })
    }

    base64ToBlob(base64String) {
        debugger;

         const byteCharacters = atob(base64String); // Decode the Base64 data
        const byteNumbers = new Array(byteCharacters.length);

        // Convert the data to an array of byte values
        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }

        // Create a blob object from the array of byte values
        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: 'application/pdf' }); // Adjust the MIME type as needed

        return blob;
        // const byteCharacters = atob(base64String);
        // const byteArrays = [];

        // for (let offset = 0; offset < byteCharacters.length; offset += 512) {
        //     const slice = byteCharacters.slice(offset, offset + 512);
        //     const byteNumbers = new Array(slice.length);

        //     for (let i = 0; i < slice.length; i++) {
        //         byteNumbers[i] = slice.charCodeAt(i);
        //     }

        //     const byteArray = new Uint8Array(byteNumbers);
        //     byteArrays.push(byteArray);
        // }
        // return new Blob(byteArrays, { type: contentType });
    }
}