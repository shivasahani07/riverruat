import { LightningElement, api, track } from 'lwc';
import HIKER_RANK from "@salesforce/resourceUrl/hikerrank";
import NEXT_BADGE from "@salesforce/resourceUrl/nextbadge";
import GO_COLOURS from "@salesforce/resourceUrl/gocolours";
import PROGRESS_BAR from "@salesforce/resourceUrl/progressbar";


export default class Lwc_lmsCourse extends LightningElement {
    

    hikerrank = HIKER_RANK;
    nextbadge = NEXT_BADGE;
    gocolours = GO_COLOURS;
    progressbar=PROGRESS_BAR;

    @api headerText = 'Header Text';
    @api contentText = 'Content Text';
    @api panelStyle = '';

    @track showcourses= true;
    @track showmodules = false;
    // @track showsummary = false;
    @track courseId;
    @track showcoursesbtn = true;
    @track showgotoLmsbtn= false;
    @track showquizsummary = false;

    handleshowmodules(){
        this.showmodules = true;
        this.showcourses = false;
        this.showquizsummary = false;
        this.showcoursesbtn = true;
        this.showgotoLmsbtn= false;
    }
     handleshowcourses(){
         this.showmodules = false;
        this.showcourses = true;
        this.showquizsummary = false;
        this.showcoursesbtn = true;
        this.showgotoLmsbtn= false;

    }
     handleshowsummary(){
         this.showmodules = false;
        this.showcourses = false;
        this.showquizsummary = true;
        this.showcoursesbtn = false;
        this.showgotoLmsbtn= true;

    }

    handleMessage(event){
        this.courseId = event.detail;
        this.handleshowmodules();
    }

}