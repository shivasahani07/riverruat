@RestResource(urlMapping='/CreateTicket')
global class MobileApp_CreateTicket {
    @HttpPost
    global static void CreateTicket() { 
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;

        try {
            String requestString = req.requestBody != null ? req.requestBody.toString() : '';
            if (String.isBlank(requestString)) {
                MobileApp_Wrapper.setResponse(400, 'Empty request body', null);
                return;
            }

            MobileApp_Wrapper.MobileApp_CreateTicket wrp = 
                (MobileApp_Wrapper.MobileApp_CreateTicket) JSON.deserialize(
                    requestString, 
                    MobileApp_Wrapper.MobileApp_CreateTicket.class
                );

            if (String.isBlank(wrp.UserId)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide UserId', null);
                return;
            }
            if (String.isBlank(wrp.description)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide description', null);
                return;
            }
            if (String.isBlank(wrp.SS1)) {
                MobileApp_Wrapper.setResponse(401, 'Please provide SS1', null);
                return;
            }

            Salesforce_Support__c ticket = new Salesforce_Support__c();
            ticket.Status__c = 'Open';
            ticket.Subject__c = 'Lead Management System';
            ticket.Description__c = wrp.description;
            insert ticket;

            Map<String, String> screenshotMap = new Map<String, String>{
                'SS1' => wrp.SS1,
                'SS2' => wrp.SS2,
                'SS3' => wrp.SS3,
                'SS4' => wrp.SS4,
                'SS5' => wrp.SS5
            };

            List<ContentVersion> versionList = new List<ContentVersion>();
            for (String label : screenshotMap.keySet()) {
                String base64 = screenshotMap.get(label);

                if (String.isNotBlank(base64)) {
                    if (base64.contains(',')) {
                        base64 = base64.split(',')[1];
                    }

                    versionList.add(new ContentVersion(
                        Title = label,
                        PathOnClient = label + '.jpg',
                        VersionData = EncodingUtil.base64Decode(base64),
                        IsMajorVersion = true
                    ));
                }
            }
            
            insert versionList;

            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            String imageHtml = '';

            List<ContentVersion> insertedVersions = [
                SELECT Id, ContentDocumentId, Title 
                FROM ContentVersion 
                WHERE Id IN :versionList
            ];

            String baseUrl = 'https://' + System.Url.getOrgDomainUrl().getHost();
            //String baseUrl = 'https://rivermobilityprivatelimited2--riverlms.sandbox.file.force.com';
            System.debug('baseUrl ====>'+baseUrl);

            for (ContentVersion cv : insertedVersions) {
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId = ticket.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));

                imageHtml += '<img style="height:100px;width:100px;" src="' + baseUrl +
                    '/servlet/rtaImage?eid=' + ticket.Id +
                    '&feoid=' + cv.ContentDocumentId +
                    '" alt="' + cv.Title + '"/>';
            }


            System.debug('imageHtml =====>'+ imageHtml);

            insert linksToInsert;

            ticket.Description__c += imageHtml;
            update ticket;

            Integration_Log__c logObj = new Integration_Log__c(
                Integration_Type__c = 'Mobile App',
                // Request_Payload__c = JSON.serializePretty(body),
                Response_Payload__c = 'Support ticket Created successfully: ' + ticket.Id,
                Status__c = 'Success'
            );
            insert logObj;

            MobileApp_Wrapper.setResponse(200, 'Support ticket Created successfully: '+ ticket.Id, null);

        } catch (Exception e) {
            String errorMsg = e.getMessage();
            if (errorMsg != null && errorMsg.length() > 255) {
                errorMsg = errorMsg.substring(0, 255);
            }

            // Integration_Log__c logObj = new Integration_Log__c(
            //     Integration_Type__c = 'Mobile App',
            //     Request_Payload__c = JSON.serializePretty(body),
            //     Response_Payload__c = 'Error: ' + errorMsg,
            //     Error_Message__c = errorMsg,
            //     Status__c = 'Failed'
            // );
            // insert logObj;

            System.debug('Error: ' + e.getStackTraceString() + ' Message ====>' + e.getMessage() + ' Line Number ====>' + e.getLineNumber());
            MobileApp_Wrapper.setResponse(500, 'Internal server error: ' + errorMsg, null);
        }
    }
}