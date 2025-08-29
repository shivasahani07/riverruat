import { LightningElement, wire, track } from 'lwc';
import wiredCourses from '@salesforce/apex/Handlecourses.wiredCourses';
import updateCourseDetails from '@salesforce/apex/Handlecourses.updateCourseDetails';
import My_STAR from "@salesforce/resourceUrl/star";
import LMS_IMAGE1 from "@salesforce/resourceUrl/lmsimage1";
import LMS_IMAGE2 from "@salesforce/resourceUrl/lmsimage2";
import LMS_IMAGE3 from "@salesforce/resourceUrl/lmsimage3";
import RED_HEART from "@salesforce/resourceUrl/redheart";
import PLAIN_HEART from "@salesforce/resourceUrl/plainheart";

export default class Lwc_courseComponent extends LightningElement {

    star = My_STAR;
    lmsimage1 = LMS_IMAGE1;
    lmsimage2 = LMS_IMAGE2;
    lmsimage3 = LMS_IMAGE3;
    redheart=RED_HEART;
    plainheart= PLAIN_HEART;


    /*cards = [
        { id: 1, header: 'Card 1 Header', body: 'Card 1 Body', footer: 'Card 1 Footer',  image: 'https://cdn.freecodecamp.org/curriculum/cat-photo-app/cats.jpg' },
        { id: 2, header: 'Card 2 Header', body: 'Card 2 Body', footer: 'Card 2 Footer',  image: 'https://cdn.freecodecamp.org/curriculum/cat-photo-app/cats.jpg' },
        { id: 3, header: 'Card 3 Header', body: 'Card 3 Body', footer: 'Card 3 Footer',  image: 'https://cdn.freecodecamp.org/curriculum/cat-photo-app/cats.jpg' }
    ];*/

    @track courses = [];

    @wire(wiredCourses)
    wiredDataHandler(result) {
        debugger;
        if (result.data) {
            debugger;
            if (result.data.length > 0) {
                var tempcourses = [];
                for (var i = 0; i < result.data.length; i++) {
                    if(this.isOdd(i+1)){
                        tempcourses.push(
                        {   id: result.data[i].Id, 
                            name: result.data[i].Course_Name__c,
                            ratingvalue: 5, 
                            rating: this.handlestarrating(5), 
                            body: 'Card 1 Body', 
                            footer: 'Card 1 Footer',
                             image: this.lmsimage1,
                             showplainheart : (result.data[i].IsFavourite__c != undefined &&   result.data[i].IsFavourite__c == true) ? false : true,
                              showredheart : (result.data[i].IsFavourite__c != undefined &&   result.data[i].IsFavourite__c == false) ? false : true } 
                         )
                    }
                    else if(this.isEven(i+1)){
                         tempcourses.push(
                        {   id: result.data[i].Id, 
                            name: result.data[i].Course_Name__c,
                            ratingvalue: 5, 
                            rating: this.handlestarrating(5), 
                            body: 'Card 1 Body', 
                            footer: 'Card 1 Footer', 
                            image:this.lmsimage2,
                            showplainheart : (result.data[i].IsFavourite__c != undefined &&   result.data[i].IsFavourite__c == true) ? false : true,
                            showredheart : (result.data[i].IsFavourite__c != undefined &&   result.data[i].IsFavourite__c == false) ? false : true }
                         )
                    }
                    
                }

                this.courses = tempcourses;
            }
            // Process data
        } else if (result.error) {
            // Handle error
            console.error('Error fetching data:', result.error);
        }
    }

    // this.lms + '/image1.png'

    handlestarrating(rating){
        var starvalue = parseInt(rating);
        var tempArray = [];
        for(var i=0; i<starvalue; i++){
            tempArray.push({url:"star"});
        }
        return tempArray;
    }

isEven (number) {
  return number % 2 === 0;
}

//check if the number is odd
isOdd (number) {
  return number % 2 !== 0;
}

    handleButtonClick(event) {
        debugger;
        var courseId = event.target.dataset.id;
        const customEvent = new CustomEvent('courseevent', {
            detail: { data: courseId }
        });
        this.dispatchEvent(customEvent);
    }

    handleheartClick(event){
        debugger;
        var courseId = event.target.dataset.id;
        var indexvalue = event.currentTarget.dataset.rowindex;
        this.updatecourse(courseId,true, indexvalue, 'plainheart');
    }
    handleRedheartClick(event){
        debugger;
        var courseId = event.target.dataset.id;
        var indexvalue = event.currentTarget.dataset.rowindex;
         this.updatecourse(courseId,false, indexvalue, 'redheart');
    }

    updatecourse(courseId,isfavourite, indexvalue, heartstring ){
        updateCourseDetails({ courseId: courseId, favourite: isfavourite })
            .then((result) => {
                if(result){

                    var tempcourseArray = [...this.courses];
                    if(heartstring =='plainheart'){
                        tempcourseArray[indexvalue].showplainheart = false;
                        tempcourseArray[indexvalue].showredheart = true;
                    }
                    else if(heartstring =='redheart'){
                        tempcourseArray[indexvalue].showplainheart = true;
                        tempcourseArray[indexvalue].showredheart = false;
                    }
                   
                    this.courses = [...tempcourseArray];
                }
            })
            .catch((error) => {
                this.error = error;
                this.contacts = undefined;
            });

    }

}