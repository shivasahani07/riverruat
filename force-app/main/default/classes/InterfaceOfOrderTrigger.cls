/**
 * @description       : 
 * @author            : Aniket Karmakar
 * @group             : 
 * @last modified on  : 10-16-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public interface InterfaceOfOrderTrigger {

    void beforeInsert();
    void beforeUpdate();
    void beforeDelete();
    void afterInsert();
    void afterUpdate();
    void afterDelete();
    
}