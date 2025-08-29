import { LightningElement,track } from 'lwc';
import myImage1 from '@salesforce/resourceUrl/colorsMain';
export default class LwcDashboard extends LightningElement {

    @track myImageUrl1 =myImage1;
    showChildComponent = false;
     


     
    openModal() {
        this.showChildComponent = true;
    }
    

}