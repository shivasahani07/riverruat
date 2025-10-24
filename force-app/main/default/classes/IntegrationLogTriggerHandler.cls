/**
 * @description       : It will send email to group memeber(RSA Failure group) for RSA Integration Failure
 * @author            : Ram Kumar
 * @group             :
 * @Created Date	  : 23-10-2025 
 * @last modified on  : 
 * @last modified by  : ram.K@utilitarianLabs.com
**/
public class IntegrationLogTriggerHandler {

    public static void handleAfterInsert(List<Integration_Log__c> newLogs) {
        System.debug('Entering handleAfterInsert with ' + newLogs.size() + ' log(s)');

        List<String> chassisNos = new List<String>();

        for (Integration_Log__c log : newLogs) {
            System.debug('Processing log: ' + log.Id);

            if (log.Integration_Type__c == 'RSA' &&
                log.Status__c == 'Failed' &&
                String.isNotBlank(log.Request_Payload__c)) {

                System.debug('Log qualifies for RSA failure processing');

                try {
                    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(log.Request_Payload__c);
                    String chassisNo = (String) payload.get('vehicleChassisNo');

                    if (String.isNotBlank(chassisNo)) {
                        chassisNos.add(chassisNo);
                        System.debug('Extracted chassis number: ' + chassisNo);
                    } else {
                        System.debug('Chassis number is blank in payload');
                    }
                } catch (Exception e) {
                    System.debug('Error parsing JSON payload: ' + e.getMessage());
                }
            }
        }

        if (chassisNos.isEmpty()) {
            System.debug('No valid chassis numbers found. Exiting.');
            return;
        }

        System.debug('Total chassis numbers collected: ' + chassisNos);

        Map<String, Vehicle> chassisToVehicleMap = new Map<String, Vehicle>();
        for (Vehicle v : [
            SELECT Id, VehicleIdentificationNumber
            FROM Vehicle
            WHERE VehicleIdentificationNumber IN :chassisNos
        ]) {
            chassisToVehicleMap.put(v.VehicleIdentificationNumber, v);
        }

        if (chassisToVehicleMap.isEmpty()) {
            System.debug('No matching vehicles found. Exiting.');
            return;
        }

        System.debug('Vehicles matched: ' + chassisToVehicleMap.keySet());

        List<Order> orders = [
            SELECT Id, OrderNumber, Status, RecordType.Name, Assigned_Vehicle__c, Assigned_Vehicle__r.VehicleIdentificationNumber
            FROM Order
            WHERE Assigned_Vehicle__c IN :chassisToVehicleMap.values()
        ];

        if (orders.isEmpty()) {
            System.debug('No related orders found. Exiting.');
            return;
        }

        System.debug('Related orders found: ' + orders.size());

        List<String> toAddresses = getEmailsFromPublicGroup('RSA Failure Group');
        System.debug('Email addresses from group: ' + toAddresses);

        if (toAddresses.isEmpty()) {
            System.debug('No recipients found in RSA Failure Group. Exiting.');
            return;
        }

        EmailTemplate template;
        try {
            template = [SELECT Id, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'RSA_Failure_Template' LIMIT 1];
            System.debug('Email template found: ' + template.Id);
        } catch (Exception e) {
            System.debug('Email Template not found: ' + e.getMessage());
            return;
        }

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.debug('Current user used for TargetObjectId: ' + currentUser.Id);

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        List<OrgWideEmailAddress> oweaList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'support@rideriver.com' LIMIT 1];
        if (oweaList.isEmpty()) {
            System.debug('OrgWideEmailAddress not found. Exiting.');
            return;
        }

        for (Order order : orders) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setTargetObjectId(currentUser.Id);
            mail.setOrgWideEmailAddressId(oweaList[0].Id);
            mail.setSaveAsActivity(false);

            Vehicle vehicle = null;
            if (order.Assigned_Vehicle__r != null) {
                String vin = order.Assigned_Vehicle__r.VehicleIdentificationNumber;
                if (vin != null && chassisToVehicleMap.containsKey(vin)) {
                    vehicle = chassisToVehicleMap.get(vin);
                }
            }

            // Replace placeholders in template bodies
            String plainBody = replacePlaceholders(template.Body, order, vehicle);
            String htmlBody = replacePlaceholders(template.HtmlValue, order, vehicle);

            mail.setPlainTextBody(plainBody);
            mail.setHtmlBody(htmlBody);

            // Set a subject dynamically or from template placeholder
            mail.setSubject('RSA Integration Failure – Action Required for Order: ' + (order.OrderNumber != null ? order.OrderNumber : ''));

            emailsToSend.add(mail);
            System.debug('Email prepared for Order: ' + order.OrderNumber);
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
            System.debug('Emails sent: ' + emailsToSend.size());
        } else {
            System.debug('No emails to send.');
        }
    }

    private static List<String> getEmailsFromPublicGroup(String groupName) {
        System.debug('Fetching emails from group: ' + groupName);

        List<String> emails = new List<String>();

        Group grp = [SELECT Id FROM Group WHERE Name = :groupName LIMIT 1];
        if (grp == null) {
            System.debug('Group not found: ' + groupName);
            return emails;
        }

        List<GroupMember> members = [
            SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :grp.Id
        ];

        List<Id> userIds = new List<Id>();
        for (GroupMember gm : members) {
            if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = TRUE]) {
            if (String.isNotBlank(u.Email)) {
                emails.add(u.Email);
                System.debug('Email added: ' + u.Email);
            }
        }

        return emails;
    }

    private static String replacePlaceholders(String body, Order order, Vehicle vehicle) {
        if (body == null) return '';

        body = body.replace('{!Order.OrderNumber}', order.OrderNumber != null ? order.OrderNumber : '');
        body = body.replace('{!Order.Status}', order.Status != null ? order.Status : '');
        body = body.replace('{!Order.Record_Type_Name__c}', order.RecordType != null ? order.RecordType.Name : '');
        body = body.replace('{!Order.Assigned_Vehicle__r}', vehicle != null && vehicle.VehicleIdentificationNumber != null ? vehicle.VehicleIdentificationNumber : '');

        return body;
    }
}