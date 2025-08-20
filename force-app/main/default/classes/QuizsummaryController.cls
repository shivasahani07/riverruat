public class QuizsummaryController {

    @AuraEnabled( cacheable=true)
    public static quizResponsewrapper fetchModuleDetails(){
        quizResponsewrapper quizResponsewrap = new quizResponsewrapper();

         Map<String, Map<String, String>> MapOfModulebySesionName = new Map<String, Map<String, String>>();
        Map<String, Map<String, String>> MapOfModulewithSessionwithScore = new Map<String, Map<String, String>>();
        List<Course_Module__c> coursemodules =[SELECT Account__c,Completion_Status__c,Course_Master__c,Description__c,End_Date__c,Module_Name__c,Module_Number__c,Module_Type__c,Start_Date__c,
                                (SELECT Description__c,End_Time__c,Id,Name,Schedule_Date__c,Session_Name__c,Session_Sequence__c,Session_Type__c,Start_Time__c,Status__c,URL__c,Video_Link__c 
                                FROM Course_Sessions__r ) 
                                FROM Course_Module__c];

        List<Course_Sessions__c> cousrseSession = [SELECT Account__c,Content__c,Course_Module__c,Course_Module__r.Module_Name__c,Course_Module__r.course_master__c, Description__c,End_Time__c,Id,Name,Schedule_Date__c,Session_Name__c,Session_Sequence__c,Session_Type__c,Start_Time__c,Status__c,URL__c,Video_Link__c 
                                                    FROM Course_Sessions__c where Course_Module__r.Course_Master__r.IsActive__c=true  ];
        

        if(cousrseSession.size()> 0){
            for (Course_Sessions__c cm : cousrseSession) {
                
                if(MapOfModulebySesionName.containsKey(cm.Course_Module__r.Module_Name__c)){
                    Map<String, String> ExistingMapOfSession =  MapOfModulebySesionName.get(cm.Course_Module__r.Module_Name__c);
                    ExistingMapOfSession.put(cm.Session_Name__c,  '0' + '-'+ '0'+ '-'+ cm.Course_Module__r.course_master__c);
                    MapOfModulebySesionName.put(cm.Course_Module__r.Module_Name__c, ExistingMapOfSession);
                }
                else{
                     Map<String, String> NewMapOfSession =  new Map<String, String>();
                    NewMapOfSession.put(cm.Session_Name__c,  '0' + '-'+ '0'+ '-'+cm.Course_Module__r.course_master__c);
                    MapOfModulebySesionName.put(cm.Course_Module__r.Module_Name__c, NewMapOfSession);
                }
                
            }
        }
        
        quizResponsewrap.coursemoduleRecord = coursemodules;
        List<Quiz_Response__c> quizResponse = [SELECT Course_Sessions__c, Course_Sessions__r.Session_Name__c,Course_Sessions__r.Course_Module__c,Course_Sessions__r.Course_Module__r.Module_Name__c, CreatedDate,Id,Name,OwnerId,Point_Scored__c,Questions__c,Quiz_Template__c,Quiz_Template__r.Name, Total_Score__c FROM Quiz_Response__c where OwnerId =: UserInfo.getUserId()];
        quizResponsewrap.quizResponseRecord = quizResponse;
        if(quizResponse.size() >0){
            for(Quiz_Response__c qr : quizResponse){
                System.debug('qr ==> ' + qr);
                System.debug('qr.Course_Sessions__r.Course_Module__r.Module_Name__ ==> ' + qr.Course_Sessions__r.Course_Module__r.Module_Name__c);
                System.debug('qr.Course_Sessions__r.Session_Name__c ==> ' + qr.Course_Sessions__r.Session_Name__c);
                System.debug('qr.Point_Scored__c ==> ' + qr.Point_Scored__c);
                System.debug('qr.Total_Score__c ==> ' + qr.Total_Score__c);
                System.debug('MapOfModulewithSessionwithScore ==> ' + MapOfModulewithSessionwithScore);
                if(MapOfModulewithSessionwithScore.containskey(qr.Course_Sessions__r.Course_Module__r.Module_Name__c)){
                    Map<String, String> ExistingmapofSessionwithScore = MapOfModulewithSessionwithScore.get(qr.Course_Sessions__r.Course_Module__r.Module_Name__c);
                    if(ExistingmapofSessionwithScore.containsKey(qr.Course_Sessions__r.Session_Name__c)){
                        String PointsScoredwithTotal = ExistingmapofSessionwithScore.get(qr.Course_Sessions__r.Session_Name__c);
                        if(PointsScoredwithTotal.contains('-')){
                            List<String> ScoredList = PointsScoredwithTotal.split('-');
                            Decimal PointScored = Decimal.valueOf(ScoredList[0]) + (qr.Point_Scored__c != null ? qr.Point_Scored__c : 0) ;
                            Decimal TotalScore = Decimal.valueOf(ScoredList[1]) + (qr.Total_Score__c != null ? qr.Total_Score__c : 0) ;
                            String scoredString =  String.valueOf(PointScored) + '-'+ String.valueOf(TotalScore);
                            ExistingmapofSessionwithScore.put(qr.Course_Sessions__r.Session_Name__c,scoredString );

                        }
                         MapOfModulewithSessionwithScore.put(qr.Course_Sessions__r.Course_Module__r.Module_Name__c, ExistingmapofSessionwithScore);
                    }
                    else{
                        //Map<String, string> NewmapofSessionwithScore = new Map<String, String>();
                        Decimal PointScored = qr.Point_Scored__c != null ? qr.Point_Scored__c : 0 ;
                        Decimal TotalScore =qr.Total_Score__c != null ? qr.Total_Score__c : 0 ;

                        if(PointScored >0 && TotalScore >0 ){
                            String scoredString =  String.valueOf(qr.Point_Scored__c) + '-'+ String.valueOf(qr.Total_Score__c);
                            ExistingmapofSessionwithScore.put(qr.Course_Sessions__r.Session_Name__c,scoredString );
                            //MapOfModulewithSessionwithScore.put(qr.Course_Sessions__r.Course_Module__r.Module_Name__c,NewmapofSessionwithScore );
                        }
                        else{
                            String scoredString =  '0' + '-'+ '0';
                            ExistingmapofSessionwithScore.put(qr.Course_Sessions__r.Session_Name__c,scoredString );
                        }
                        MapOfModulewithSessionwithScore.put(qr.Course_Sessions__r.Course_Module__r.Module_Name__c,ExistingmapofSessionwithScore );
                    }
                }
                else{
                    Map<String, string> NewmapofSessionwithScore = new Map<String, String>();
                    Decimal PointScored = qr.Point_Scored__c != null ? qr.Point_Scored__c : 0 ;
                    Decimal TotalScore =  qr.Total_Score__c != null ? qr.Total_Score__c : 0 ;
                    if(PointScored >0 && TotalScore >0 ){
                        String scoredString =  String.valueOf(qr.Point_Scored__c) + '-'+ String.valueOf(qr.Total_Score__c);
                        NewmapofSessionwithScore.put(qr.Course_Sessions__r.Session_Name__c,scoredString );
                            //MapOfModulewithSessionwithScore.put(qr.Course_Sessions__r.Course_Module__r.Module_Name__c,NewmapofSessionwithScore );

                    }
                    else{
                        String scoredString =  '0' + '-'+ '0';
                        NewmapofSessionwithScore.put(qr.Course_Sessions__r.Session_Name__c,scoredString );
                            
                        }
                        MapOfModulewithSessionwithScore.put(qr.Course_Sessions__r.Course_Module__r.Module_Name__c,NewmapofSessionwithScore );
                }
            }
        }
        for(String Str : MapOfModulebySesionName.keyset()){
            if(!MapOfModulewithSessionwithScore.containskey(Str)){
                Map<String, string> existingsessionMap = MapOfModulebySesionName.get(str);
                MapOfModulewithSessionwithScore.put(str,existingsessionMap);
            }
            else{
                Map<string, string> NewexistingSessionMap = MapOfModulebySesionName.get(str);
                Map<string, string> MapOfSessionwithScore = MapOfModulewithSessionwithScore.get(Str);
                for(String sessionstr : NewexistingSessionMap.keyset()){
                    if(!MapOfSessionwithScore.containskey(sessionstr)){
                        MapOfSessionwithScore.put(sessionstr, NewexistingSessionMap.get(sessionstr));
                    }
                }

                MapOfModulewithSessionwithScore.put(str, MapOfSessionwithScore);
            }
        }
        quizResponsewrap.MapOfModulewithSessionwithScoreRecord = MapOfModulewithSessionwithScore;
        return quizResponsewrap;
        
    }

    Public class quizResponsewrapper{
        @AuraEnabled
        Public List<Course_Module__c> coursemoduleRecord;
        @AuraEnabled
        Public Map<String, Map<String, String>> MapOfModulewithSessionwithScoreRecord;
        @AuraEnabled
        public List<Quiz_Response__c> quizResponseRecord;
    }

}