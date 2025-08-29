import { LightningElement, wire, track } from 'lwc';
import QUIZ_SUMMARY from "@salesforce/resourceUrl/quizsummary";
import fetchModuleDetails from "@salesforce/apex/QuizsummaryController.fetchModuleDetails";
import SCORE_BADGE from "@salesforce/resourceUrl/scoreabdge";



export default class Lwc_quizsummary extends LightningElement {

    quizsummary = QUIZ_SUMMARY;
    scoreabdge = SCORE_BADGE;
    @track quizsummary;
    @track ModuleDetails;
    @track quizdetails;
    @track quizsummarydetails;
    @track showmodules=false;
    @track showLeadershipDashboard = false;

    handleshowLeaderDashboard(){
        debugger;
        this.showLeadershipDashboard = true;
    }

    @wire(fetchModuleDetails)
    wiredresponse(data, error){
        if(data.data){
            debugger;
            this.quizsummary = data.data.MapOfModulewithSessionwithScoreRecord;
            this.ModuleDetails = data.data.coursemoduleRecord;
            this.quizdetails = data.data.quizResponseRecord;
            if(this.quizsummary){
                this.createquizData(this.quizsummary);
            }
            
        }
        if(error){
            this.error = error;
        }
    }

    createquizData(quizdetails){
        var tempdata =[];
        // for(var i=0; i<quizdetails.length; i++){
        //     var tempQuizObj = {};
        //     const moduleexist = tempdata.find(item => item.module ===  quizdetails[i].Course_Sessions__r.Course_Module__r.Module_Name__c);
        //     if(moduleexist != null){


        //     }
            
        // }

        for (let key in quizdetails) {
                var tempmodule = key;
            if (quizdetails.hasOwnProperty(key)) {
                const sessionvalue = quizdetails[key];
                var i=0
                for (let key in sessionvalue){
                    var tempObj = {};
                    if(i==0){
                        tempObj.module = tempmodule;
                    }
                    tempObj.session = key;
                    var score = sessionvalue[key];
                    if(score.includes('-')){
                        var myArray = score.split("-");
                        var tempointscore = parseInt(myArray[0]);
                        var temptotalscore = parseInt(myArray[1]);
                        if(myArray.length >2 && myArray[2] != undefined && myArray[2] != null){
                            tempObj.courseId = myArray[2];  
                        }
                        if( temptotalscore >0){
                            tempObj.pointscore = tempointscore;
                             tempObj.totalscore = temptotalscore;
                             tempObj.showbadge = true;
                             tempObj.showsessionbtn = false;
                        }
                        else{
                            tempObj.pointscore = '-';
                            tempObj.totalscore = '-';
                            tempObj.showsessionbtn = true;
                            tempObj.showbadge = false;
                        }
                    }
                    tempdata.push(tempObj);
                    i++;
                }

               // console.log(`Key: ${key}, Value: ${value}`);
            }
            
        }
        this.quizsummarydetails = [...tempdata];
    }

    handletakequiz(event){
        debugger;
        var moduleId = event.target.dataset.id;
         var courseId = event.target.dataset.id;
        const customEvent = new CustomEvent('courseevent', {
            detail: { data: courseId }
        });
        this.dispatchEvent(customEvent);

    }
}