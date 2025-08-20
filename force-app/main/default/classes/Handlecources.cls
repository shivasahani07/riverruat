public class Handlecources {
    
    @AuraEnabled
    Public Static wrapperHandler getCourseModulesSessions(String courseId){
        set<Id> sessionIds=new set<Id>();
        wrapperHandler WH=new wrapperHandler();
        List<Quiz_Template__c> getAllQuestionTemplatesRelatedTo=new List<Quiz_Template__c>();
        List<Course_Module__c> coursemaster=[Select Id,Module_Name__c,Module_Number__c,Course_Master__c,Course_Master__r.Course_Name__c,
                                             (Select Id,Session_Name__c,Content__c,URL__c From Course_Sessions__r Order by Session_Sequence__c) From Course_Module__c Where Course_Master__c!=null AND Course_Master__c=:courseId AND Course_Master__r.isActive__c=true order By Module_Number__c];

        if(!coursemaster.isEmpty()){
             for(Course_Module__c CM:coursemaster){
                     for(Course_Sessions__c cs:CM.Course_Sessions__r){
                          if(cs.Id!=null){
                                sessionIds.add(cs.Id);
                          }
                    }
             }
        } 

        if(!sessionIds.isEmpty()){
             getAllQuestionTemplatesRelatedTo =[Select Id,Name,Course_Sessions__c,(Select Id,Question_Name__c,Question_Options__c From Questions__r order By Question_Sequence__c) From Quiz_Template__c Where Course_Sessions__c!=null AND Course_Sessions__c=:sessionIds]; 
        } 
        if(!coursemaster.isEmpty()){
              WH.courseModule=coursemaster;
        } 
        if(!getAllQuestionTemplatesRelatedTo.isEmpty()) {
            WH.sessionRelatedQuiz=getAllQuestionTemplatesRelatedTo;
        }                       
        return WH;
    }

    @AuraEnabled
    Public static String createQuizresponse(List<Quiz_Response__c> getAllQuizresponse){

        if(!getAllQuizresponse.isEmpty()){
            upsert getAllQuizresponse;
           
        }
         return 'SUCCESS';
    }

    @AuraEnabled(Cacheable=true)
    Public Static List<Course_Master__c> wiredCourses(){

       List<Course_Master__c> CourseReclist = [SELECT Account__c,Course_Code__c,IsFavourite__c,Course_Name__c,Course_Type__c,CreatedById,CreatedDate,Description__c,Duration_In_Months__c,End_Date__c,Id,IsActive__c,Name,OwnerId,Start_Date__c FROM Course_Master__c where IsActive__c = true order By order_number__c ASC];
       return CourseReclist;
    }
    
    @auraEnabled
    Public static String updateCourseDetails(String courseId, boolean favourite){
        Course_master__c cm = new Course_master__c();
        cm.Id = courseId;
        cm.IsFavourite__c =favourite;
        update cm;
        return 'SUCCESS';
    }

    Public class wrapperHandler{
        @AuraEnabled
        Public List<Course_Module__c> courseModule{get;set;}
        @AuraEnabled
        Public List<Quiz_Template__c> sessionRelatedQuiz{get;set;}
    }

}