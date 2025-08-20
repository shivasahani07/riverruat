import { LightningElement,track,api } from 'lwc';
import getCourseModulesSessions from "@salesforce/apex/Handlecourses.getCourseModulesSessions";

export default class LMS_Module extends LightningElement {

quizImageUrl = quizImageResource;
@track visibleSections = 5; // Initially show 5 sections
@track selectedQuizValue;
@track courseDetails=[];
@track PreapredData=[];
@track recordsFrombackend=[];

@api courseid;

@track showstart_quiz_scrren=true;



get filteredData() {
        return this.PreapredData.slice(0, this.visibleSections);
    }

    get isSeeMoreVisible() {
        return this.PreapredData.length > this.visibleSections;
    }

    handleSeeMore() {
        // Increase the number of visible sections by 5 or up to the total number of sections
        this.visibleSections += 5;
        if (this.visibleSections > this.PreapredData.length) {
            this.visibleSections = this.PreapredData.length;
        }
    }

    connectedCallback() {
        debugger;
        this.getdoinitMethods();
    }

    getdoinitMethods(){
        debugger;
        getCourseModulesSessions({courseId:this.courseid})
        .then(result=>{
              if(result !=null && result !=undefined){
                  this.courseDetails=[...result];
                  this.prepareCousrseDetailData(this.courseDetails)
              }
              console.log('courseDetails',JSON.stringify(this.courseDetails));
        })
        .catch(error=>{
            console.log('error',error);
        })
    }

    prepareCousrseDetailData(courseDetails){
         debugger;
        let courseModule_Related_sessions=[];
         console.log('courseDetails',courseDetails);
         if(courseDetails!=undefined && courseDetails!=null && courseDetails.length>0){
               courseDetails.forEach(coursemaster => {
                    let courseobj={coursename:null,courseId:null,modules:null};
                    let Module={modulename:null,moduleId:null,sessions:[]}
                   if(coursemaster.Course_Master__r){
                       courseobj.coursename=coursemaster.Course_Master__r.Course_Name__c;
                       courseobj.courseId=coursemaster.Course_Master__r.Id;
                   }
                   if(coursemaster.Module_Name__c){
                        Module.modulename=coursemaster.Module_Name__c;
                        Module.moduleId=coursemaster.Id;
                        if(coursemaster.Course_Sessions__r){
                             coursemaster.Course_Sessions__r.forEach(coursesession=>{
                                 let sessiondetail={sessionname:null,sessionId:null}
                                 if(coursesession.Id && coursesession.Session_Name__c){
                                    sessiondetail.sessionname=coursesession.Session_Name__c;
                                    sessiondetail.sessionId=coursesession.Id;
                                    Module.sessions.push(sessiondetail);
                                 }
                             })
                        }
                   }
                   courseobj.modules=Module;
                   courseModule_Related_sessions.push(courseobj);
               }); 
               console.log('courseModule_Related_sessions',JSON.stringify(courseModule_Related_sessions));
               this.PreapredData=[...courseModule_Related_sessions];
         }
    }


    // Dummy data for the accordion, replace with your actual data structure
    PreapredData = [
        {
            modules: {
                modulename: 'Introduction to Gocolors and its mission',
                moduleId: 'module1',
                sessions: [
                    { sessionname: 'Session 1', sessionId: 's1' },
                    { sessionname: 'Session 2', sessionId: 's2' }
                ]
            }
        },
        // ... more modules
    ];

    // Dummy options for the quiz questions, replace with your actual data
    quizOptionsQuestion1 = [
        { label: 'To be the leading retailer in high-end electronics', value: 'electronics' },
        { label: 'To provide a wide variety of high-quality and affordable bottom wear for women', value: 'bottomWear' },
        { label: 'To expand rapidly into international markets', value: 'international' },
        { label: 'To become the largest online retailer', value: 'onlineRetailer' }
    ];

    quizOptionsQuestion2 = [
        // ... options for question 2
        { label: 'Womens footwear', value: 'footwear' },
        { label: 'Mens formal wear', value: 'formalwear' },
        { label: 'Womens bottom wear', value: 'bottomwear' },
        { label: 'Childrens toys', value: 'Childrenstoys' }
    ];

    quizOptionsQuestion3 = [
        // ... options for question 3
        { label: 'By offering the lowest prices', value: 'lowestprice' },
        { label: ' By providing the fastest shipping', value: 'fastestshipping' },
        { label: 'By offering a wide range of colors and styles in bottom wear', value: 'bottomwear' }
    ];

    Handleclicksession(event) {
        const sessionId = event.currentTarget.dataset.sessionId;
    }

    handleQuizChange(event) {
        this.selectedQuizValue = event.detail.value;
    }

    handleSubmitQuiz() {
        // handle quiz submission
    }

    handleStratQuiz(){
        debugger;
        this.showstart_quiz_scrren=false;
    }


}