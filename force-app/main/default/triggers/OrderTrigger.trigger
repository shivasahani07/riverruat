/**
* @description       :
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             :
* @last modified on  : 10-16-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
Trigger OrderTrigger on Order (before insert, after update, after insert, before update,before delete,after delete) {
    new ParentOrderTriggerHandler().run();
}