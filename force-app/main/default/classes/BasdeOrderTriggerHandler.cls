/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public abstract class BasdeOrderTriggerHandler implements InterfaceOfOrderTrigger{
    private Boolean hasAlreadyRun = false;

    public void run(){
        if(hasAlreadyRun)  return;
        
        hasAlreadyRun = true;

        if(Trigger.isBefore){
          if(Trigger.isInsert) beforeInsert();
          else if(Trigger.isUpdate) beforeUpdate();
          else if(Trigger.isDelete) beforeDelete();
        }
        if(Trigger.isAfter){
          if(Trigger.isInsert) afterInsert();
          else if(Trigger.isUpdate) afterUpdate();
          else if(Trigger.isDelete) afterDelete();
        }
    }
    public virtual void beforeInsert(){}
    public virtual void beforeUpdate(){}
    public virtual void beforeDelete(){}
    public virtual void afterInsert(){}
    public virtual void afterUpdate(){}
    public virtual void afterDelete(){}


}