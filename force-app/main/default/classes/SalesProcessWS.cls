global class SalesProcessWS {
    
    public class SalesProcessWSException extends Exception {}
    static private Boolean SalesProcessWS_FullRegistrationFlow_Step1 = false;
    static public void setSalesProcessWS_FullRegistrationFlow_Step1(Boolean val){
    	SalesProcessWS_FullRegistrationFlow_Step1 = val;
    }
    static public Boolean getSalesProcessWS_FullRegistrationFlow_Step1(){
    	return SalesProcessWS_FullRegistrationFlow_Step1;
    }
    
    webservice static String UpdateUsageDetails(String xmlRequest){
        system.debug('UpdateUsageDetails_xmlRequest:' + xmlRequest);
        String xmlResponse = '';
        String csvResponse = '';
        Savepoint sp = Database.setSavepoint();
        //Boolean to know if there is an Error in all the process.
        Boolean isError = false;
        
        try{
            /*
            <Request>
              <Opportunities>
                <Opportunity payloadid="" username="">
                  <Field field-name="" value=""/>
                </Opportunity>
              </Opportunities>
            </Request>
            */
            XMLDom xmlReader;
            XMLDom.Element xmlRecords;
            try{
                xmlReader = new XMLDom(xmlRequest);
                xmlRecords = xmlReader.getElementByTagName('Request').getElementByTagName('Opportunities');
            }catch(Exception e){
                throw new SalesProcessWSException('Bad formatted XML.');
            }
            
            //username->payloadid->Field(name)->Field(value)
            Map<String, Map<String, Map<String, String>>> xmlMap = new Map<String, Map<String,Map<String, String>>>();
            Map<String, String> fieldType = new Map<String, String>();
            
            //ErrorMap contains info for the xmlResponse.
            Map<String, List<String>> errorMap = new Map<String, List<String>>();
            List<String> SortedUsernames = new List<String>();
            
            Map<String, SalesProcessMappingField__c> csMap = new Map<String, SalesProcessMappingField__c>();
        	
        	for(String key : SalesProcessMappingField__c.getAll().keySet()){
        		csMap.put(key.toLowerCase().trim(), SalesProcessMappingField__c.getAll().get(key));
        	}
            
            Set<String> username2Query = new Set<String>();
            
            for(XMLDom.Element oppElem : xmlRecords.childNodes){
                //Iterate all Opportunities
                String username = oppElem.getAttribute('username');
                String payload = oppElem.getAttribute('payloadid');
                
                if(username != null && username != ''){
                    username = username.toLowerCase().trim();
                    
                    if(!xmlMap.containsKey(username)){
                        xmlMap.put( username, new Map<String, Map<String, String>> ());
                        //This is used for the xmlResponse, to build it in the same order as the request.
                        SortedUsernames.add(username);
                    }
                    
                    xmlMap.get(username).put( payload, new Map<String, String>() );
                    
                    //Pre establish that it will throw an error for Username not found. Later on, if it finds one, it will replace with a Success.
                    //List goes like this: Status, Description, OpportunityId
                    errorMap.put(username, new List<String>{'Error','Username Not Found.',''});
                    
                    for(XMLDom.Element FieldElem : oppElem.childNodes){
                        //Iterate Each Field in Object
                        String Field = FieldElem.getAttribute('field-name').toLowerCase().trim();
                        
                        system.debug('Field1: ' + field);
                        
                        if( csMap.containsKey( Field ) ){
	                		Field = csMap.get(Field).SF_Field_API_Name__c;
	                		if(Field == null){ Field = '';}
	                		Field = Field.toLowerCase().trim();
	                	}else{
	                		//Error
	                		errorMap.get(username)[0] = 'Error';
	                    	errorMap.get(username)[1] = 'No field mapping for ' + Field;
	                        isError = true;
	                        break;
	                	}
                        
                        if( Field == ''){
	                		errorMap.get(username)[0] = 'Error';
	                    	errorMap.get(username)[1] = 'Could not determine Salesforce Field for field ' + Field;
	                        isError = true;
	                        break;
	                	}
                        
                        system.debug('Field2: ' + field);
                        
                        //Get the value for said Field.
                        if(!xmlMap.get(username).get(payload).containsKey(Field)){
                            xmlMap.get(username).get(payload).put(Field, FieldElem.getAttribute('value') );
                        }
                    }
                    String mandatoryFieldsResult = mandatoryFieldsCheck(new List<String>(), xmlMap.get(username).get(payload).keySet());
                    if( mandatoryFieldsResult == ''){
                        username2Query.add(username);
                    }else{
                        isError = true;
                        errorMap.get(username)[0] = 'Error';
                        errorMap.get(username)[1] = mandatoryFieldsResult;
                    }
                }else{
                    isError = true;
                    SortedUsernames.add('');
                    if(!errorMap.containsKey('')){
                        errorMap.put('', new List<String>{payload});
                    }else{
                        errorMap.get('').add(payload);
                    }
                }
            }
            
            Map<Id, String> usernameByConId = new Map<Id, String>();
            
            for(Contact us : [SELECT username__c, Id FROM Contact WHERE username__c IN :username2Query]){
                //We relate each username to a Contact Id
                usernameByConId.put( us.Id, us.Username__c.toLowerCase().trim() );
                if(errorMap.containsKey(us.username__c.toLowerCase().trim())){
                    //Found the username, so we clear the Username Not Found error.
                    errorMap.get(us.username__c.toLowerCase().trim())[0] = 'Success';
                    errorMap.get(us.username__c.toLowerCase().trim())[1] = '';
                }
            }
            
            List<Opportunity> opp2Upd = new List<Opportunity>();
            Map<Id, String> usernameByOppId = new Map<Id, String>();
            
            Set<Id> conIds = new Set<Id>();
            Set<String> foundOppFromUsername = new Set<String>();
            
            Id SAASRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
            
            for(Opportunity opp : [SELECT Id, Primary_Contact__c FROM Opportunity WHERE IsClosed = false AND Primary_Contact__c IN :usernameByConId.keySet() AND RecordTypeId = :SAASRecordType ORDER BY CreatedDate desc]){
                //if(!conIds.contains(ocr.ContactId)){
                //  conIds.add(ocr.ContactId);
                    
                    String username = usernameByConId.get(opp.Primary_Contact__c);
                    //This is used for detecting those usernames with no found Opportunity
                    foundOppFromUsername.add(username);
                    
                    Boolean everythingOk = true;
                    Opportunity sObj = new Opportunity(Id = opp.Id);
                    //Establish the OpportunityId for the xmlResponse
                    if(errorMap.get(username)[2] != ''){
                        errorMap.get(username)[2] += ';';
                    }
                    errorMap.get(username)[2] += String.valueOf(sObj.Id);
                    
                    for( String payload : xmlMap.get(username).keySet() ){
                        //Iterate through the Payloads in the Map.
                        
                        for( String fName : xmlMap.get(username).get(payload).keySet() ){
                            //Iterate all Fields contained in the Map
                            Map<String, String> fieldMap = xmlMap.get(username).get(payload);
                            
                            if( !fieldType.containsKey(fName) ){
                                //Make sure the field actually exists in the Opportunity, else we add it to the ErrorMap and break from processing this User.
                                if(!Schema.SObjectType.Opportunity.fields.getMap().containsKey(fName)){
                                    isError = true;
                                    errorMap.get(username)[0] = 'Error';
                                    errorMap.get(username)[1] = 'Field ' + fName + ' Not Found.';
                                    everythingOk = false;
                                    break;
                                }
                                //Add it to the fieldMap for future reference.
                                fieldType.put(fName, Schema.SObjectType.Opportunity.fields.getMap().get(fName).getDescribe().getType().name());
                            }
                            //We save the value from the xml to the Object, if it fails, it returns an Error Message.
                            String setFieldResult = setField( sObj, fName, fieldType, fieldMap.get(fName) );
                            if( setFieldResult != ''){
                                isError = true;
                                errorMap.get(username)[0] = 'Error';
                                errorMap.get(username)[1] = 'Error in Field ' + fName + '. ' + setFieldResult;
                                everythingOk = false;
                                break;
                            }
                        }
                    }
                    
                    if(everythingOk){
                        //Populate map for later reference in creating the xmlResponse.
                        usernameByOppId.put(sObj.Id, username);
                        opp2Upd.add(sObj);
                    }
                //}
            }
            /*
            for(OpportunityContactRole ocr : [SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE Opportunity.IsClosed = false AND ContactId IN :usernameByConId.keySet() ORDER BY Opportunity.CreatedDate desc]){
                //Only process once per Contact Id
                if(!conIds.contains(ocr.ContactId)){
                    conIds.add(ocr.ContactId);
                    
                    String username = usernameByConId.get(ocr.ContactId);
                    //This is used for detecting those usernames with no found Opportunity
                    foundOppFromUsername.add(username);
                    
                    Boolean everythingOk = true;
                    Opportunity sObj = new Opportunity(Id = ocr.OpportunityId);
                    //Establish the OpportunityId for the xmlResponse
                    errorMap.get(username)[2] = String.valueOf(sObj.Id);
                    
                    for( String payload : xmlMap.get(username).keySet() ){
                        //Iterate through the Payloads in the Map.
                        
                        for( String fName : xmlMap.get(username).get(payload).keySet() ){
                            //Iterate all Fields contained in the Map
                            Map<String, String> fieldMap = xmlMap.get(username).get(payload);
                            
                            if( !fieldType.containsKey(fName) ){
                                //Make sure the field actually exists in the Opportunity, else we add it to the ErrorMap and break from processing this User.
                                if(!Schema.SObjectType.Opportunity.fields.getMap().containsKey(fName)){
                                    errorMap.get(username)[0] = 'Error';
                                    errorMap.get(username)[1] = 'Field ' + fName + ' Not Found.';
                                    everythingOk = false;
                                    break;
                                }
                                //Add it to the fieldMap for future reference.
                                fieldType.put(fName, Schema.SObjectType.Opportunity.fields.getMap().get(fName).getDescribe().getType().name());
                            }
                            //We save the value from the xml to the Object, if it fails, it returns an Error Message.
                            String setFieldResult = setField( sObj, fName, fieldType, fieldMap.get(fName) );
                            if( setFieldResult != ''){
                                errorMap.get(username)[0] = 'Error';
                                errorMap.get(username)[1] = 'Error in Field ' + fName + '. ' + setFieldResult;
                                everythingOk = false;
                                break;
                            }
                        }
                    }
                    
                    if(everythingOk){
                        //Populate map for later reference in creating the xmlResponse.
                        usernameByOppId.put(sObj.Id, username);
                        opp2Upd.add(sObj);
                    }
                }
            }
            */
            
            
            if(!opp2Upd.isEmpty()){
                //We update the Opportunities. If there is an error we record it in the ErrorMap.
                List<Database.SaveResult> srList = Database.update(opp2Upd, false);
                
                for(Integer i=0; i < opp2Upd.size(); i++){
                    Database.SaveResult sr = srList[i];
                    Id oppId = opp2Upd[i].Id;
                    
                    if(!sr.isSuccess()){
                        isError = true;
                        String errorMsg = '';
                        for(Database.error er : sr.getErrors()){                    
                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
                        }
                        errorMap.get(usernameByOppId.get(oppId))[0] = 'Error';
                        errorMap.get(usernameByOppId.get(oppId))[1] = 'DML Error: ' + errorMsg;
                    }
                }
            }
            
            for( String username : errorMap.keySet() ){
                //Check if there where usernames with no Opportunity found.
                if( username!= '' && !foundOppFromUsername.contains(username) && errorMap.get(username)[0] != 'Error'){
                    isError = true;
                    errorMap.get(username)[0] = 'Error';
                    errorMap.get(username)[1] = 'No Opportunity was found.';
                }
            }
            
            xmlResponse = '';
            csvResponse = '"Payload","Status","Commited","Description","RecordId","Time"\n';
            Integer emptyUsernameIndex = 0;
            //Create the xmlResponse
            for(String username : SortedUsernames){
                if(username != null &&  username != ''){
                    for( String payload : xmlMap.get(username).keySet() ){
                        
                        xmlResponse += '<Opportunity payloadid="'+payload+'" recordid="'+errorMap.get(username)[2]+'" ';
                        
                        xmlResponse += 'status="'+errorMap.get(username)[0]+'" description="'+errorMap.get(username)[1]+'" commited="changethisvalueforiserror"/>';
                        
                        if( errorMap.get(username)[0].equalsIgnoreCase('Error') ){
                            isError = true;
                        }
                        csvResponse += '"'+payload+'","'+errorMap.get(username)[0]+'","changethisvalueforiserror","'+errorMap.get(username)[1]+'","'+errorMap.get(username)[2]+'","'+system.now()+'"\n';
                    }
                }else{
                    if(errorMap.get(username).size()>emptyUsernameIndex){
                        xmlResponse += '<Opportunity payloadid="'+errorMap.get(username)[emptyUsernameIndex]+'" recordid="" status="Error" description="Missing attribute [username]. Cannot be empty." commited="false" />';
                        csvResponse += '"'+errorMap.get(username)[emptyUsernameIndex]+'","Error","false","Missing attribute [username]. Cannot be empty.","","'+system.now()+'"\n';
                        emptyUsernameIndex += 1;
                    }
                    isError = true;
                }
            }
            
            xmlResponse = xmlResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            csvResponse = csvResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            
            if(!isError){
                xmlResponse = '<response><status code="200" description=""><Opportunities>' + xmlResponse;
            }else{
                xmlResponse = '<response><status code="500" description="Errors were produced while inserting/updating records, please refer to the result records to see the detailed error messages. None of these records was committed to the database."><Opportunities>' + xmlResponse;
                
                if(!Test.isRunningTest()){
                    //If any error has ocurrer, then RollBack Database
                    Database.rollback(sp);
                    SendEmail('UpdateUsageDetails', 'SAAS Usage Process Completed with Errors.', csvResponse);
                }
            }
            xmlResponse += '</Opportunities></status></response>';
            
        }catch(Exception e){
            String result = CatchProcessing(e);
            
            Database.rollback(sp);
            
            xmlResponse = '<response><status code="500" description="' + result + '" /></response>';
        }
        return xmlResponse;
    }
    
    webservice static String RenewalUpgradeDowngradeFlow(String xmlRequest){
        system.debug('RenewalUpgradeDowngradeFlow_xmlRequest:' + xmlRequest);
        String xmlResponse = '';
        String csvResponse = '';
        Savepoint sp = Database.setSavepoint();
        //List of fields that are mandatory. NAME OF FIELD MUST GO IN LOWER CASE.
        List<String> mandatoryFields = new List<String>{'package_number__c', 'expiration_date__c', 'closedate'};
        //Boolean to know if there is an Error in all the process.
        Boolean isError = false;
        
        try{
            /*
            <Request>
              <Opportunities>
                <Opportunity payloadid="" username="">
                  <Field field-name="" value=""/>
                </Opportunity>
              </Opportunities>
            </Request>
            */
            
            XMLDom xmlReader;
            XMLDom.Element xmlRecords;
            try{
                xmlReader = new XMLDom(xmlRequest);
                xmlRecords = xmlReader.getElementByTagName('Request').getElementByTagName('Opportunities');
            }catch(Exception e){
                throw new SalesProcessWSException('Bad formatted XML.');
            }
            
            //username->payload->Field(name)->Field(value)
            Map<String, Map<String, Map<String, String>>> xmlMap = new Map<String, Map<String,Map<String, String>>>();
            Map<String, String> fieldType = new Map<String, String>();
            
            //ErrorMap contains info for the xmlResponse.
            Map<String, List<String>> errorMap = new Map<String, List<String>>();
            
            Map<String, String> packageTypByUsername = new Map<String, String>();
            List<String> SortedUsernames = new List<String>();
            Set<String> username2Query = new Set<String>();
            
            for(XMLDom.Element oppElem : xmlRecords.childNodes){
                //Iterate all Opportunities
                String username = oppElem.getAttribute('username');
                String payload = oppElem.getAttribute('payloadid');
                if(username != null && username != ''){
                    username = username.toLowerCase().trim();
                    
                    if(!xmlMap.containsKey(username)){
                        xmlMap.put( username, new Map<String, Map<String, String>> ());
                        //This is used for the xmlResponse, to build it in the same order as the request.
                        SortedUsernames.add(username);
                    }
                    
                    xmlMap.get(username).put( payload, new Map<String, String>() );
                    
                    //Pre establish that it will throw an error for Username not found. Later on, if it finds one, it will replace with a Success.
                    //List goes like this: Status, Description, OpportunityId
                    errorMap.put(username, new List<String>{'Error','Username Not Found.', ''});
                    
                    for(XMLDom.Element FieldElem : oppElem.childNodes){
                        //Iterate Each Field in Object
                        String Field = FieldElem.getAttribute('field-name').toLowerCase().trim();
                        //Get the value for said Field.
                        if(!xmlMap.get(username).get(payload).containsKey(Field)){
                            xmlMap.get(username).get(payload).put(Field, FieldElem.getAttribute('value') );
                        }
                    }
                    String mandatoryFieldsResult = mandatoryFieldsCheck(mandatoryFields, xmlMap.get(username).get(payload).keySet());
                    if( mandatoryFieldsResult == ''){
                        username2Query.add(username);
                    }else{
                        isError = true;
                        errorMap.get(username)[0] = 'Error';
                        errorMap.get(username)[1] = mandatoryFieldsResult;
                    }
                    if(xmlMap.get(username).get(payload).containsKey('package_type__c')){
                        packageTypByUsername.put(username, xmlMap.get(username).get(payload).get('package_type__c'));
                    }
                }else{
                    isError = true;
                    SortedUsernames.add('');
                    if(!errorMap.containsKey('')){
                        errorMap.put('', new List<String>{payload});
                    }else{
                        errorMap.get('').add(payload);
                    }
                }
            }
            
            Map<Id, String> usernameByConId = new Map<Id, String>();
            Map<String, Contact> ConIdByUsername = new Map<String,Contact>();
            
            //Find Contacts with Username equals to those from the xml
            for(Contact us : [SELECT username__c, Id, Name, AccountId, Account.Name FROM Contact WHERE username__c IN :username2Query]){
                //We relate each username to a Contact Id
                usernameByConId.put( us.Id, us.Username__c.toLowerCase().trim() );
                ConIdByUsername.put( us.Username__c.toLowerCase().trim(), us );
                if(errorMap.containsKey(us.username__c.toLowerCase().trim())){
                    //Found the username, so we clear the Username Not Found error.
                    errorMap.get(us.username__c.toLowerCase().trim())[0] = 'Success';
                    errorMap.get(us.username__c.toLowerCase().trim())[1] = '';
                }
            }
            
            List<Opportunity> opp2Upd = new List<Opportunity>();
            List<Opportunity> opp2Ins = new List<Opportunity>();
            List<String> sortedUsernames4Insert = new List<String>();
            
            Map<String, Opportunity> opp2InsByUsername = new Map<String, Opportunity>();
            Map<Id, String> usernameByOppId = new Map<Id, String>();
            
            Set<Opportunity> opp2Close = new Set<Opportunity>();
            Set<Id> conIds = new Set<Id>();
            
            Id SAASRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
            
            //Find Open Opportunities with Primary Contact as the Contacts already found
            for(Opportunity opp : [SELECT Id, Primary_Contact__c, Package_Type__c FROM Opportunity WHERE IsClosed = false AND Primary_Contact__c IN :usernameByConId.keySet() AND RecordTypeId = :SAASRecordType ORDER BY CreatedDate desc]){
                //Opportunities we are to close.
                opp2Close.add(opp);
                //Populate map for later reference in creating the xmlResponse.
                usernameByOppId.put(opp.Id, usernameByConId.get(opp.Primary_Contact__c));
            }
            /*
            //Find Open Opportunities that are related to the Contacts through a OpportunityContactRole
            for(OpportunityContactRole ocr : [SELECT OpportunityId, ContactId FROM OpportunityContactRole WHERE Opportunity.IsClosed = false AND ContactId IN :usernameByConId.keySet() ORDER BY Opportunity.CreatedDate desc]){
                //Only process once per Contact Id
                if(!conIds.contains(ocr.ContactId)){
                    conIds.add(ocr.ContactId);
                    
                    //In case we already found the Opportunity.
                    if(!opp2Close.contains(ocr.OpportunityId)){
                        opp2Close.add(ocr.OpportunityId);
                        //Populate map for later reference in creating the xmlResponse.
                        usernameByOppId.put(ocr.OpportunityId, usernameByConId.get(ocr.ContactId));
                    }
                }
            }
            */
            //Close found Opportunities.
            Map<String, String> stagename4NewOppByUsername = new Map<String, String>();
            Map<String, Integer> closedOppStage = new Map<String, Integer>();
            closedOppStage.put('Free',0);
            closedOppStage.put('Standard',1);
            closedOppStage.put('Premium',2);
            for( Opportunity opp : opp2Close){
                String oldPType = opp.Package_Type__c;
                String newPType = opp.Package_Type__c;
                
                opp.StageName = 'Closed Won';
                stagename4NewOppByUsername.put(usernameByOppId.get(opp.Id), 'Paid');
                
                if( oldPType!='' && oldPType!=null ){
                    
                    if( packageTypByUsername.containsKey( usernameByOppId.get(opp.Id) ) ){
                        if( closedOppStage.containsKey(newPType) ){
                            newPType = packageTypByUsername.get( usernameByOppId.get(opp.Id) );
                        }
                    }
                    
                    //If old value is greater than new value, the it's a loss.
                    if( closedOppStage.get(oldPType) > closedOppStage.get(newPType) ){
                        opp.StageName = 'Closed Lost';
                        stagename4NewOppByUsername.put(usernameByOppId.get(opp.Id), 'Free Trial');
                    }
                }
                
                opp.End_Date__c = system.today();
                
                opp2Upd.add(opp);
            }
            
            //Here we create the New Opportunities and populate it's fields
            for( String username : ConIdByUsername.keySet() ){
                Opportunity sObj = new Opportunity(RecordTypeId = SAASRecordType);
                Boolean everythingOk = true;
                
                for( String payload : xmlMap.get(username).keySet() ){
                    //Iterate through the Opportunities in the Map.
                    for( String fName : xmlMap.get(username).get(payload).keySet() ){
                        //Iterate all Fields contained in the Map
                        Map<String, String> fieldMap = xmlMap.get(username).get(payload);
                        
                        if( !fieldType.containsKey(fName) ){
                            //Make sure the field actually exists in the Opportunity, else we add it to the ErrorMap and break from processing this User.
                            if(!Schema.SObjectType.Opportunity.fields.getMap().containsKey(fName)){
                                errorMap.get(username)[0] = 'Error';
                                errorMap.get(username)[1] = 'Field ' + fName + ' Not Found.';
                                isError = true;
                                everythingOk = false;
                                break;
                            }
                            //Add it to the fieldMap for future reference.
                            fieldType.put(fName, Schema.SObjectType.Opportunity.fields.getMap().get(fName).getDescribe().getType().name());
                        }
                        //We save the value from the xml to the Object, if it fails, it returns an Error Message.
                        String setFieldResult = setField( sObj, fName, fieldType, fieldMap.get(fName) );
                        if( setFieldResult != ''){
                            isError = true;
                            errorMap.get(username)[0] = 'Error';
                            errorMap.get(username)[1] = 'Error in Field ' + fName + '. ' + setFieldResult;
                            everythingOk = false;
                            break;
                        }
                    }
                    //Determines the StageName for the new Opportunity based on the Package Type
                    if(!stagename4NewOppByUsername.containsKey(username)){
                        if( xmlMap.get(username).get(payload).containsKey('package_type__c') ){
                            String pType = xmlMap.get(username).get(payload).get('package_type__c');
                            if( pType.equalsIgnoreCase('Free') ){
                                stagename4NewOppByUsername.put(username, 'Free Trial');
                            }else{
                                stagename4NewOppByUsername.put(username, 'Paid');
                            }
                        }
                    }
                }
                
                if(everythingOk){
                    sObj.AccountId =  ConIdByUsername.get(username).AccountId;
                    sObj.Primary_Contact__c = ConIdByUsername.get(username).Id;
                    sObj.SAAS_Contact_Name__c = ConIdByUsername.get(username).Id; //CHECK THIS LATER ON
                    sObj.Name = ConIdByUsername.get(username).Account.Name +' '+ ConIdByUsername.get(username).Name +' '+ sObj.Package_Number__c;
                    
                    if( stagename4NewOppByUsername.containsKey(username) ){
                        sObj.StageName = stagename4NewOppByUsername.get(username);
                    }
                    
                    opp2Ins.add(sObj);
                    opp2InsByUsername.put(username, sObj);
                    sortedUsernames4Insert.add(username);
                }
            }
            
            if(!opp2Upd.isEmpty()){
                //Send to Update the Previously Closed Opportunities. If any throw an Error, we added to its ErrorMap.
                List<Database.SaveResult> srList = Database.update(opp2Upd, false);
                
                for(Integer i=0; i < opp2Upd.size(); i++){
                    Database.SaveResult sr = srList[i];
                    Id oppId = opp2Upd[i].Id;
                    
                    if(!sr.isSuccess()){
                        String errorMsg = '';
                        isError = true;
                        for(Database.error er : sr.getErrors()){                    
                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
                        }
                        
                        errorMap.get(usernameByOppId.get(oppId))[0] = 'Error';
                        errorMap.get(usernameByOppId.get(oppId))[1] = 'DML Error when Updating Opportunity: ' + errorMsg;
                        
                        //For those Closing Opportunities that threw an error, We Must Not Allow the Insert of the New Opportunity
                        if(opp2InsByUsername.containsKey(usernameByOppId.get(oppId))){
                            opp2InsByUsername.remove(usernameByOppId.get(oppId));
                            for(Integer y=0;y<sortedUsernames.size(); y++){
                                if( sortedUsernames[y].equalsIgnoreCase(usernameByOppId.get(oppId)) ){
                                    sortedUsernames.remove(y);
                                    opp2Ins.remove(y);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            
            if(!opp2InsByUsername.isEmpty()){
                //Insert the New Opportunities. If any throw an Error, we added to its ErrorMap.
                List<OpportunityContactRole> ocr2Ins = new List<OpportunityContactRole>();
                List<String> sortedUsername4OCRInsert = new List<String>();
                
                List<Database.SaveResult> srList = Database.insert(opp2Ins, false);
                
                for(Integer i=0; i <  sortedUsernames4Insert.size(); i++){
                    String oppId = String.valueOf(srList[i].getId());
                    if( oppId == null || oppId == 'null'){
                        oppId = '';
                    }
                    
                    errorMap.get(sortedUsernames4Insert[i])[2] = String.valueOf(oppId);
                    
                    if(!srList[i].isSuccess()){
                        String errorMsg = '';
                        isError = true;
                        for(Database.error er : srList[i].getErrors()){                    
                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
                        }
                        
                        errorMap.get(sortedUsernames4Insert[i])[0] = 'Error';
                        errorMap.get(sortedUsernames4Insert[i])[1] = 'DML Error when Inserting Opportunity: ' + errorMsg;
                        
                    }else{
                        //For each new Opportunity, we create a New OpportunityContactRole.
                        OpportunityContactRole ocr = new OpportunityContactRole();
                        ocr.OpportunityId = srList[i].getId();
                        ocr.ContactId = ConIdByUsername.get(sortedUsernames4Insert[i]).Id;
                        ocr.isPrimary = true;
                        
                        ocr2Ins.add(ocr);
                        sortedUsername4OCRInsert.add(sortedUsernames4Insert[i]);
                    }
                }
                
                if( !ocr2Ins.isEmpty() ){
                    //Insert the OpportunityContactRoles. If any throw an Error, we added to its ErrorMap.
                    List<Database.SaveResult> srList2 = Database.insert(ocr2Ins, false);
                    
                    for(Integer i=0; i < sortedUsername4OCRInsert.size(); i++){
                        String ocrId = String.valueOf(srList2[i].getId());
                        
                        if(!srList2[i].isSuccess()){
                            String errorMsg = '';
                            isError = true;
                            for(Database.error er : srList2[i].getErrors()){
                                errorMsg += 'Error Message: ' + er.getMessage() + ';';
                            }
                            
                            errorMap.get(sortedUsername4OCRInsert[i])[0] = 'Error';
                            errorMap.get(sortedUsername4OCRInsert[i])[1] = 'DML Error when Inserting Opportunity Contact Role: ' + errorMsg;                            
                        }
                    }
                }
            }
            
            xmlResponse = '';
            csvResponse = '"Payload","Status","Commited","Description","RecordId","Time"\n';
            Integer emptyUsernameIndex = 0;
            //Create the xmlResponse
            for(String username : SortedUsernames){
                if(username != null &&  username != ''){
                    for( String payload : xmlMap.get(username).keySet() ){
                        xmlResponse += '<Opportunity payloadid="'+payload+'" recordid="'+errorMap.get(username)[2]+'" ';
                        
                        xmlResponse += 'status="'+errorMap.get(username)[0]+'" description="'+errorMap.get(username)[1]+'" commited="changethisvalueforiserror"/>';
                        
                        if( errorMap.get(username)[0].equalsIgnoreCase('Error') ){
                            isError = true;
                        }
                        csvResponse += '"'+payload+'","'+errorMap.get(username)[0]+'","changethisvalueforiserror","'+errorMap.get(username)[1]+'","'+errorMap.get(username)[2]+'","'+system.now()+'"\n';
                    }
                }else{
                    if(errorMap.get(username).size()>emptyUsernameIndex){
                        xmlResponse += '<Opportunity payloadid="'+errorMap.get(username)[emptyUsernameIndex]+'" recordid="" status="Error" description="Missing attribute [username]. Cannot be empty." commited="false" />';
                        csvResponse += '"'+errorMap.get(username)[emptyUsernameIndex]+'","Error","false","Missing attribute [username]. Cannot be empty.","","'+system.now()+'"\n';
                        emptyUsernameIndex += 1;
                    }
                    isError = true;
                }
            }
            
            xmlResponse = xmlResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            csvResponse = csvResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            
            if(!isError){
                xmlResponse = '<response><status code="200" description=""><Opportunities>' + xmlResponse;
            }else{
                xmlResponse = '<response><status code="500" description="Errors were produced while inserting/updating records, please refer to the result records to see the detailed error messages. None of these records was committed to the database."><Opportunities>' + xmlResponse;
                if(!Test.isRunningTest()){
                    //If any error has ocurrer, then RollBack Database
                    Database.rollback(sp);
                    SendEmail('RenewalUpgradeDowngradeFlow', 'SAAS Renewal/Upgrade Process Completed with Errors.', csvResponse);
                }
            }
            xmlResponse += '</Opportunities></status></response>';
            
        }catch(Exception e){
            String result = CatchProcessing(e);
            
            Database.rollback(sp);
            
            xmlResponse = '<response><status code="500" description="' + result + '" /></response>';
        }
        return xmlResponse;
    }
    
    webservice static String FullRegistrationFlow(String xmlRequest){
        system.debug('FullRegistrationFlow_xmlRequest:' + xmlRequest);
        String xmlResponse = '';
        String csvResponse = '';
        //String wsStep = '';
        Savepoint sp = Database.setSavepoint();
        //Boolean to know if there is an Error in all the process.
        Boolean isError = false;
        
        Map<String,List<String>> mandatoryFieldMap4Step1 = new Map<String, List<String>>();
        mandatoryFieldMap4Step1.put('lead', new List<String>{'lastname','company','username__c'});
        
        Map<String,List<String>> mandatoryFieldMap4Step2 = new Map<String, List<String>>();
        mandatoryFieldMap4Step2.put('lead', new List<String>{'username__c'});
        mandatoryFieldMap4Step2.put('opportunity', new List<String>{'package_number__c','expiration_date__c'});
        
        MonitorRecursionClass.setFullRegistrationFlowMonitor(true);
        try{
            /*
            <Request>
              <NewLeads approval="0">
                <NewLead payloadid="">
                  <Field field-name="" value=""/>
                  <Field field-name="" value=""/>
                </NewLead>
              </NewLeads>
            </Request>
            */
            
            XMLDom xmlReader;
            XMLDom.Element xmlRecords;
            try{
                xmlReader = new XMLDom(xmlRequest);
                xmlRecords = xmlReader.getElementByTagName('Request').getElementByTagName('NewLeads');
                //wsStep = xmlRecords.getAttribute('approval');
            }catch(Exception e){
                throw new SalesProcessWSException('Bad formatted XML.');
            }
            
            //payload->Object(name)->Field(name)->Field(value)
            Map<String, Map<String, Map<String, String>>> xmlMap = new Map<String, Map<String,Map<String, String>>>();
            
            //Maps to take care of the fieldTypes in the Objects we process.
            Map<String, Map<String, String>> fieldType = new Map<String, Map<String, String>>();
            Map<String, Schema.DescribeSObjectResult> objectDescribe = new Map<String, Schema.DescribeSObjectResult>();
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            
            //ErrorMap contains info for the xmlResponse.
            Map<String, List<String>> errorMap = new Map<String, List<String>>();
            
            Map<String, List<Lead>> leads2InsMap = new Map<String, List<Lead>>();
            List<String> sortedPayload = new List<String>();
            List<String> sortedPayload4LeadInsert = new List<String>();
            List<String> sortedPayload4LeadUpdate = new List<String>();
            
        	Map<String, List<String>> leadsEmails2Query = new Map<String, List<String>>();
        	
        	Map<String, Boolean> payloadActive = new Map<String, Boolean>();
        	
        	Map<String, SalesProcessMappingField__c> csMap = new Map<String, SalesProcessMappingField__c>();
        	
        	for(String key : SalesProcessMappingField__c.getAll().keySet()){
        		csMap.put(key.toLowerCase().trim(), SalesProcessMappingField__c.getAll().get(key));
        	}
        	
            for(XMLDom.Element leadElem : xmlRecords.childNodes){
                //Iterate all Leads
                String payload = leadElem.getAttribute('payloadid');
                Lead ld = null;
                String email = '';
                Boolean everythingOk = true;
                
                if(!xmlMap.containsKey(payload)){
                    xmlMap.put( payload, new Map<String, Map<String, String>> ());
                    //This is used for the xmlResponse, to build it in the same order as the request.
                    sortedPayload.add(payload);
                }
                //Pre establish that it will throw an error for Lead not found. Later on, if it finds one, it will replace with a Success.
                //List goes like this: Status, Description, LeadId, OpportunityId, ContactId, AccountId
                errorMap.put(payload, new List<String>{'Error','No Lead was Found','','','',''});
                payloadActive.put(payload, false);
                
                for(XMLDom.Element FieldElem : leadElem.childNodes){
                	
                	String Field = FieldElem.getAttribute('field-name');
                	String objectName = '';
                	
                	if(Field == null){ Field = '';}
            		Field = Field.toLowerCase().trim();
            		
                	system.debug('Field1: ' + field);
                	
                    if( field.equalsIgnoreCase('active') ){
                    	String activeVal = FieldElem.getAttribute('value');
                    	if(activeVal != null && activeVal.equalsIgnoreCase('true')){
                    		payloadActive.put(payload, true);
                    		errorMap.get(payload)[0] = 'Error';
	                        errorMap.get(payload)[1] = 'No Lead record was Found';
                    	}
                    }else{
                    	if( csMap.containsKey( Field ) ){
	                		objectName = csMap.get(Field).SF_Object_API_Name__c;
	                		if(objectName == null){ objectName = '';}
	                		objectName = objectName.toLowerCase().trim();
	                		
	                		Field = csMap.get(Field).SF_Field_API_Name__c;
	                		if(Field == null){ Field = '';}
	                		Field = Field.toLowerCase().trim();
	                	}else{
	                		//Error
	                		errorMap.get(payload)[0] = 'Error';
	                    	errorMap.get(payload)[1] = 'No field mapping for ' + Field;
	                    	everythingOk = false;
	                        isError = true;
	                        break;
	                	}
	                	
	                	if( objectName == ''){
	                		errorMap.get(payload)[0] = 'Error';
	                    	errorMap.get(payload)[1] = 'Could not determine Object for field ' + Field;
	                    	everythingOk = false;
	                        isError = true;
	                        break;
	                	}
	                	if( Field == ''){
	                		errorMap.get(payload)[0] = 'Error';
	                    	errorMap.get(payload)[1] = 'Could not determine Salesforce Field for field ' + Field;
	                    	everythingOk = false;
	                        isError = true;
	                        break;
	                	}                	
	                	
	                	system.debug('ObjectName: ' + objectName);
	                	system.debug('Field2: ' + field);
	                	
	                    if(!xmlMap.get(payload).containsKey(objectName)){
	                        xmlMap.get(payload).put( objectName, new Map<String, String>());
	                    }
	                    
	                    //Add the Object to the describe Map
	                    if(!objectDescribe.containsKey(objectName)){
	                        objectDescribe.put(objectName, gd.get(objectName).getDescribe());
	                    }
	                    
	                    //Add the Object to the fieldType Map
	                    if(!fieldType.containsKey(objectName)){
	                        fieldType.put(objectName, new Map<String, String>());
	                    }
	                    
	                    //If it's a Lead, we already take care of populating its values.
	                    if( objectName.equalsIgnoreCase('Lead') && ld == null){
	                        ld = new Lead();
	                        //We clear the ErrorMap from the No Lead error.
	                        if( payloadActive.get(payload) == false ){
		                        errorMap.get(payload)[0] = 'Success';
		                        errorMap.get(payload)[1] = '';
	                        }
	                    }
	                    //Iterate Each Field in Object
	                    
	                    if(!xmlMap.get(payload).get(objectName).containsKey(Field)){
	                        xmlMap.get(payload).get(objectName).put(Field, FieldElem.getAttribute('value') );
	                    }
	                    //Make sure the field actually exists in the Opportunity, else we add it to the ErrorMap and break from processing this User.
	                    if(!fieldType.get(objectName).containsKey(field)){
	                        if(!objectDescribe.get(objectName).fields.getMap().containsKey(field)){
	                            //Error Sequence
	                            errorMap.get(payload)[0] = 'Error';
	                            errorMap.get(payload)[1] = 'Field ' + field + ' Not Found in '+ objectName;
	                            everythingOk = false;
	                            isError = true;
	                            break;
	                        }
	                        fieldType.get(objectName).put(field, objectDescribe.get(objectName).fields.getMap().get(field).getDescribe().getType().name());
	                    }
	                    
	                    if( objectName.equalsIgnoreCase('Lead') && ld != null ){
	                    	if( field == 'username__c' ){
	                    		email = FieldElem.getAttribute('value');
	                    		if(email == null){email = '';}
	                    		
	                    	}
	                    	
	                        //If it's a Lead
	                        //We save the value from the xml to the Object, if it fails, it returns an Error Message.
	                        String setFieldResult = setField(ld, field, fieldType.get(objectName), FieldElem.getAttribute('value'));
	                        if( setFieldResult != ''){
	                            isError = true;
	                            errorMap.get(payload)[0] = 'Error';
	                            errorMap.get(payload)[1] = 'Error in Field ' + field + ' from object ' + objectName + '. ' + setFieldResult;
	                            everythingOk = false;
	                            break;
	                        }
	                        
	                    }
                    }
                }
                
                for( String objectName : xmlMap.get(payload).keySet() ){
                    String mandatoryFieldsResult = '';
                    
                    if( payloadActive.get(payload) == false ){
                    	if( mandatoryFieldMap4Step1.containsKey(objectName) ){
                    		mandatoryFieldsResult = mandatoryFieldsCheck(mandatoryFieldMap4Step1.get(objectName), xmlMap.get(payload).get(objectName).keySet());
                    	}
                    }else{
                    	if( mandatoryFieldMap4Step2.containsKey(objectName) ){
                    		mandatoryFieldsResult = mandatoryFieldsCheck(mandatoryFieldMap4Step2.get(objectName), xmlMap.get(payload).get(objectName).keySet());
                    	}
                    }
                    
                    if( mandatoryFieldsResult != ''){
                        isError = true;
                        errorMap.get(payload)[0] = 'Error';
                        errorMap.get(payload)[1] = 'Error in ' +objectName + '. ' + mandatoryFieldsResult;
                        everythingOk = false;
                        //break;
                    }
                }
                    
                //}
                if( ld != null && everythingOk){
                    //If its a Lead
                    ld.Email = ld.Username__c;
                    ld.Saas__c = true;
                    ld.Customer_Type__c = 'SAAS';
                    
                    if(!leads2InsMap.containsKey(payload)){
                    	leads2InsMap.put(payload, new List<Lead>());
                    }
                    leads2InsMap.get(payload).add(ld);
                    //sortedPayload4LeadInsert.add(payload);
                    
                    if( !leadsEmails2Query.containsKey( email.toLowerCase().trim() ) ){
            			leadsEmails2Query.put(email.toLowerCase().trim(), new List<String>());
            		}
            		leadsEmails2Query.get(email.toLowerCase().trim()).add(payload);
            		sortedPayload4LeadUpdate.add(payload);
                }
            }
            
            List<Lead> leads2Upd = new List<Lead>();
            List<Lead> leadsFound = new List<Lead>();
            List<String> sortedPayload4LeadsUpdated = new List<String>();
            List<String> sortedPayload4LeadsConvert = new List<String>();
            
            if(!leadsEmails2Query.isEmpty()){
            	//Check if lead exists with same email
            	Set<String> emailsFound = new Set<String>();
            	Set<String> emailsProcessed = new Set<String>();
            	
            	system.debug(System.Logginglevel.INFO, 'Emails: ' + leadsEmails2Query.keySet());
            	
            	for( Lead ld : [SELECT Id,Email, Company FROM Lead WHERE IsConverted = false AND Customer_Type__c = 'SAAS' AND Email IN :leadsEmails2Query.keySet()] ){
            		
            		system.debug(System.Logginglevel.INFO, 'Lead: ' + ld);
            		
            		Boolean everythingOk = true;
            		Boolean isStep1 = false;
            		
            		String email = ld.Email;
            		if(email == null){email = '';}
            		email = email.toLowerCase().trim();
            		
            		if(!emailsProcessed.contains(email)){
	            		emailsProcessed.add(email);
	            		
	            		emailsFound.add(email);
	            		
	            		for( String payload : leadsEmails2Query.get(email.toLowerCase().trim())){
	            			if(payloadActive.get(payload) == false){
	            				//Step 0
	            				//Creates or Updates Lead
	            				leads2InsMap.remove(payload);
		            			
		            			for( String fieldName : xmlMap.get(payload).get('lead').keySet()){
		            				//We save the value from the xml to the Object, if it fails, it returns an Error Message.
		            				String setFieldResult = setField(ld, fieldName, fieldType.get('lead'), xmlMap.get(payload).get('lead').get(fieldName));
		                            if( setFieldResult != ''){
		                                isError = true;
		                                errorMap.get(payload)[0] = 'Error';
		                                errorMap.get(payload)[1] = 'Error in Field ' + fieldName + ' from object ' + 'lead' + '. ' + setFieldResult;
		                                everythingOk = false;
		                                break;
		                            }
		            			}
		            			
		            			if(everythingOk){
			            			ld.Saas__c = true;
			            			leads2Upd.add(ld);
			            		}
	            			}else{
	            				//Step 1
	            				//Converts Lead
	            				isStep1 = true;
	            				leads2InsMap.remove(payload);
	            				ld.CancelWorkflowForConversion__c = true;
	            				
		            			errorMap.get(payload)[0] = 'Success';
		            			errorMap.get(payload)[1] = '';
	                    		errorMap.get(payload)[2] = ld.Id;
	            			}
	            		}
	            		
	            		if(isStep1){
	            			leadsFound.add(ld);
	            		}
	            		/*
	            		if(wsStep == '0'){
	            		
		            		for( String payload : leadsEmails2Query.get(email.toLowerCase().trim())){
		            			leads2InsMap.remove(payload);
		            			
		            			for( String fieldName : xmlMap.get(payload).get('lead').keySet()){
		            				//We save the value from the xml to the Object, if it fails, it returns an Error Message.
		            				String setFieldResult = setField(ld, fieldName, fieldType.get('lead'), xmlMap.get(payload).get('lead').get(fieldName));
		                            if( setFieldResult != ''){
		                                isError = true;
		                                errorMap.get(payload)[0] = 'Error';
		                                errorMap.get(payload)[1] = 'Error in Field ' + fieldName + ' from object ' + 'lead' + '. ' + setFieldResult;
		                                everythingOk = false;
		                                break;
		                            }
		            			}
		            		}
		            		
		            		if(everythingOk){
		            			ld.Saas__c = true;
		            			leads2Upd.add(ld);
		            		}
	            		}else{
	            			//Step to convert Leads STEP 2
	            			ld.CancelWorkflowForConversion__c = true;
	            			leadsFound.add(ld);
            				
            				for( String payload : leadsEmails2Query.get(email.toLowerCase().trim())){
		            			errorMap.get(payload)[0] = 'Success';
		            			errorMap.get(payload)[1] = '';
	                    		errorMap.get(payload)[2] = ld.Id;
            				}
	            		}*/
            		}
            	}
            	//Order the payloads based on appearance and for both, Leads found and not found.
            	Set<String> payloadsFound = new Set<String>();
            	for( String em : emailsFound){
            		for(String payload : leadsEmails2Query.get(em)){
            			payloadsFound.add(payload);
            		}
            	}
            	
            	for(String payload : sortedPayload4LeadUpdate){
            		if( payloadActive.get(payload)==false ){
	            		if( payloadsFound.contains(payload) ){
	            			sortedPayload4LeadsUpdated.add(payload);
	            		}else{
	            			sortedPayload4LeadInsert.add(payload);
	            		}
            		}else{
            			sortedPayload4LeadsConvert.add(payload);
            		}
            	}
            	system.debug('sortedPayload4LeadsUpdated: ' + sortedPayload4LeadsUpdated);
            	system.debug('sortedPayload4LeadInsert: ' + sortedPayload4LeadInsert);
            }
            
            //if(wsStep == '0'){
            	SalesProcessWS.setSalesProcessWS_FullRegistrationFlow_Step1(true);
            	
	            List<Lead> leads2Ins = new List<Lead>();
	            
	            for(Integer i=0; i < sortedPayload4LeadInsert.size(); i++){
	            	for(Lead ld : leads2InsMap.get(sortedPayload4LeadInsert[i])){
	            		leads2Ins.add(ld);
	            	}
	            }
	            
	            system.debug(System.Logginglevel.INFO, 'leads2Ins: ' + leads2Ins);
	            
	            /////Insert Leads
	            
	            if( !leads2Ins.isEmpty() ){
	                //We insert the new Leads. If any throw an Error, we added to its ErrorMap.
	                List<Lead> leadsInserted = new List<Lead>();
	                List<String> sortedPayload4LeadsInserted = new List<String>();
	                
	                List<Database.SaveResult> srList = Database.insert(leads2Ins, false);
	                
	                for(Integer i=0; i < sortedPayload4LeadInsert.size(); i++){
	                    String ldId = String.valueOf(srList[i].getId());
	                    if( ldId == null || ldId == 'null'){
	                        ldId = '';
	                    }
	                    system.debug('sortedPayload4LeadInsert[i]: ' + sortedPayload4LeadInsert[i]);
	                    system.debug('ldId: ' + ldId);
	                    errorMap.get(sortedPayload4LeadInsert[i])[0] = 'Success';
	                    errorMap.get(sortedPayload4LeadInsert[i])[2] = ldId;
	                    
	                    if(!srList[i].isSuccess()){
	                        isError = true;
	                        String errorMsg = '';
	                        
	                        for(Database.error er : srList[i].getErrors()){
	                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
	                        }
	                        errorMap.get(sortedPayload4LeadInsert[i])[0] = 'Error';
	                        errorMap.get(sortedPayload4LeadInsert[i])[1] = 'DML Error when Inserting Lead: ' + errorMsg;
	                    }else{
	                        leadsInserted.add(leads2Ins[i]);
	                        sortedPayload4LeadsInserted.add(sortedPayload4LeadInsert[i]);
	                    }
	                }
	            }
	            
	            system.debug(System.Logginglevel.INFO, 'leads2Upd: ' + leads2Upd);
	            
	            if( !leads2Upd.isEmpty()){
	            	//Update the Leads that where found
	            	List<Lead> leadsUpdated = new List<Lead>();
	                //List<String> sortedPayload4LeadsUpdated = new List<String>();
	                
	                List<Database.SaveResult> srList = Database.update(leads2Upd, false);
	                
	                for(Integer i=0; i < sortedPayload4LeadsUpdated.size(); i++){
	                    String ldId = String.valueOf(srList[i].getId());
	                    if( ldId == null || ldId == 'null'){
	                        ldId = '';
	                    }
	                    system.debug('sortedPayload4LeadsUpdated[i]: ' + sortedPayload4LeadsUpdated[i]);
	                    errorMap.get(sortedPayload4LeadsUpdated[i])[0] = 'Success';
	                    errorMap.get(sortedPayload4LeadsUpdated[i])[2] = ldId;
	                    
	                    if(!srList[i].isSuccess()){
	                        isError = true;
	                        String errorMsg = '';
	                        
	                        for(Database.error er : srList[i].getErrors()){
	                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
	                        }
	                        errorMap.get(sortedPayload4LeadsUpdated[i])[0] = 'Error';
	                        errorMap.get(sortedPayload4LeadsUpdated[i])[1] = 'DML Error when Inserting Lead: ' + errorMsg;
	                    }else{
	                        leadsUpdated.add(leads2Upd[i]);
	                        //sortedPayload4LeadsUpdated.add(sortedPayload4LeadUpdate[i]);
	                    }
	                }
	            }
	            
            //}else{
            	
                /////Search for Contacts and Accounts
                
                Map<String, List<Lead>> leadByEmail = new Map<String, List<Lead>>();
                Map<String, List<Lead>> leadByCompany = new Map<String, List<Lead>>();
                
                //ConvertMap holds the Id of the Lead as Key, and as value a List containing the Contact in index 0 and the Account in index 1
                //Lead(Id)->[Contact, Account] 
                Map<Id, List<sObject>> convertMap = new Map<Id, List<sObject>>();
                
                for(Lead l : leadsFound){
                    String email = l.Email;
                    String company = l.Company;
                    if(email == null){email = '';}
                    if(company == null){company = '';}
                    //Map for searching Contacts
                    if(!leadByEmail.containsKey(email.toLowerCase().trim())){
                        leadByEmail.put(email.toLowerCase().trim(), new List<Lead>());
                    }
                    leadByEmail.get(email.toLowerCase().trim()).add(l);
                    
                    //Map for searching Accounts
                    if(!leadByCompany.containsKey(company.toLowerCase().trim())){
                        leadByCompany.put(company.toLowerCase().trim(), new List<Lead>());
                    }
                    leadByCompany.get(company.toLowerCase().trim()).add(l);
                    
                    convertMap.put(l.Id, new List<sObject>{null,null});
                }
                
                //Search for Contacts associated with the Lead Email
                for(Contact con : [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :leadByEmail.keySet() AND Email != '' AND Customer_Type__c != 'SAAS' /*SAAS__c = false*/]){
                    for(Lead l : leadByEmail.get(con.Email.toLowerCase().trim())){
                        convertMap.get(l.Id)[0] = con;
                    }
                }
                
                //Search for Accounts associated with the Lead Company
                for(Account acc : [SELECT Id, Name FROM Account WHERE Name IN : leadByCompany.keySet() AND Name != '']){
                    for(Lead l : leadByCompany.get(acc.Name.toLowerCase().trim())){
                        convertMap.get(l.Id)[1] = acc;
                    }
                }
                
                
                //////Lead Conversion
                
                LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                List<Database.LeadConvert> leads2Convert = new List<Database.LeadConvert>();
                
                //Set the convert leads.
                for( Lead l : leadsFound ){
                    Database.LeadConvert lc = new Database.LeadConvert();
                    lc.setLeadId(l.Id);
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    
                    //We set the Contact/Account to the leadConvert according to logic.
                    if(convertMap.get(l.Id)[0] == null){
                        if(convertMap.get(l.Id)[1] != null){
                            lc.setAccountId(convertMap.get(l.Id)[1].Id);
                        }
                    }else{
                        lc.setContactId(convertMap.get(l.Id)[0].Id);
                        lc.setAccountId(((Contact)convertMap.get(l.Id)[0]).AccountId);
                    }
                    leads2Convert.add(lc);
                }
                //Desactivating workflows.
                Database.update( leadsFound , false);
                
                //Process the Lead Convert and it's Result
                List<Database.LeadConvertResult> lcrList = Database.convertLead(leads2Convert,false);
                
                List<Opportunity> opp2Upd = new List<Opportunity>();
                List<Contact> con2Upd = new List<Contact>();
                List<Account> acc2Upd = new List<Account>();
                
                ID oppRecordType = null;
                //We might already have the Description of the Opportunity.
                if(objectDescribe.containsKey('opportunity')){
                    oppRecordType = objectDescribe.get('opportunity').getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
                }else{
                    oppRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
                }
                
                Map<String, Id> leadIdByPayload = new Map<String, Id>();
                Map<Id, String> payloadByOppId = new Map<Id, String>();
                Map<Id, List<String>> payloadByConId = new Map<Id, List<String>>();
                Map<Id, List<String>> payloadByAccId = new Map<Id, List<String>>();
                Map<Id, Opportunity> oppByConId = new Map<Id, Opportunity>();
                
                Set<Id> contactIds = new Set<Id>();
                Set<Id> accountIds = new Set<Id>();
                
                for(integer i=0 ; i < lcrList.size(); i++){
                    //Check the Results from the LeadConversion.
                    Database.LeadConvertResult lcr = lcrList[i];
                    String payload = sortedPayload4LeadsConvert[i];
                    leadIdByPayload.put(payload, lcr.getLeadId());
                    
                    //Save the OpportunityId, ContactId and AccountId for use in the xmlResponse.
                    errorMap.get(payload)[3] = lcr.getOpportunityId();
                    errorMap.get(payload)[4] = lcr.getContactId();
                    errorMap.get(payload)[5] = lcr.getAccountId();
                    
                    if(lcr.isSuccess()){
                        
                        errorMap.get(payload)[0] = 'Success';
                        
                        //Update values in the Created Opportunity to those from the xml, though some fields have defaults.
                        Opportunity opp = new Opportunity(Id = lcr.getOpportunityId(), RecordTypeId = oppRecordType);
                        opp.CloseDate = system.Today();
                        opp.StageName = 'Free Trial';
                        opp.SAAS_Contact_Name__c = lcr.getContactId();
                        opp.Primary_Contact__c = lcr.getContactId();
                        
                        if(xmlMap.get(payload).containsKey('opportunity')){
                            for( String field : xmlMap.get(payload).get('opportunity').keySet()){
                                setField(opp, field, fieldType.get('opportunity'), xmlMap.get(payload).get('opportunity').get(field));
                            }
                        }
                        //The Opp Name = Lead.Company + Contact.Name + Opp.Product_Number__c.
                        //Here we set the first part of the Name. Later on we will add the rest of it.
                        //opp.Name = xmlMap.get(payload).get('lead').get('company');
                        String leadCompany = leadsFound[i].Company;
                        if(leadCompany == null){leadCompany = '';}
                        
                        opp.Name = leadCompany;
                        
                        
                        oppByConId.put(lcr.getContactId(), opp);
                        opp2Upd.add(opp);
                        payloadByOppId.put(lcr.getOpportunityId(), payload);
                        
                        Id leadId = lcr.getLeadId();
                        
                        if(xmlMap.get(payload).containsKey('contact')){
                            //Update the Contact Fields with those from the xml.
                            Contact con = new Contact(Id = lcr.getContactId());
                            
                            for( String field : xmlMap.get(payload).get('contact').keySet()){
                                setField(con, field, fieldType.get('contact'), xmlMap.get(payload).get('contact').get(field));
                            }
                            con.Username__c = xmlMap.get(payload).get('lead').get('username__c');
                            if(!contactIds.contains(lcr.getContactId())){
                                contactIds.add(lcr.getContactId());
                                con2Upd.add(con);
                            }
                            if(!payloadByConId.containsKey(lcr.getContactId())){
                                payloadByConId.put(lcr.getContactId(), new List<String>());
                            }
                            payloadByConId.get(lcr.getContactId()).add(payload);
                        }
                        
                        if(xmlMap.get(payload).containsKey('account')){
                            //Update the Account Fields with those from the xml.
                            Account acc = new Account(Id = lcr.getAccountId());
                            
                            for( String field : xmlMap.get(payload).get('account').keySet()){
                                setField(acc, field, fieldType.get('account'), xmlMap.get(payload).get('account').get(field));
                            }
                            if(!accountIds.contains(acc.Id)){
                                acc2Upd.add(acc);
                                accountIds.add(acc.Id);
                            }
                            if(!payloadByAccId.containsKey(lcr.getAccountId())){
                                payloadByAccId.put(lcr.getAccountId(), new List<String>());
                            }
                            payloadByAccId.get(lcr.getAccountId()).add(payload);
                        }
                        
                        /* DO NOT DELETE THIS SECTION YET. CODE STILL ON APPROVAL.
                        if(convertMap.get(leadId )[0] == null){
                            
                            if(xmlMap.get(payload).containsKey('contact')){
                                //Update the Contact Fields
                                Contact con = new Contact(Id = lcr.getContactId());
                                
                                for( String field : xmlMap.get(payload).get('contact').keySet()){
                                    setField(con, field, fieldType.get('contact'), xmlMap.get(payload).get('contact').get(field));
                                }
                                con2Upd.add(con);
                                payloadByConId.put(lcr.getContactId(), payload);
                            }
                            
                            if(convertMap.get(leadId)[1] == null){
                                if(xmlMap.get(payload).containsKey('account')){
                                    //Update the Account Fields
                                    Account acc = new Account(Id = lcr.getAccountId());
                                    
                                    for( String field : xmlMap.get(payload).get('account').keySet()){
                                        setField(acc, field, fieldType.get('account'), xmlMap.get(payload).get('account').get(field));
                                    }
                                    acc2Upd.add(acc);
                                    payloadByAccId.put(lcr.getAccountId(), payload);
                                }
                            }
                        }else{
                            if(xmlMap.get(payload).containsKey('lead')){
                                //Update Contacts Username field
                                if(xmlMap.get(payload).get('lead').containsKey('username__c')){
                                    Contact con = new Contact(Id = lcr.getContactId());
                                    con.Username__c = xmlMap.get(payload).get('lead').get('username__c');
                                    
                                    con2Upd.add(con);
                                    payloadByConId.put(con.Id, payload);
                                }
                            }
                        }DO NOT DELETE THIS SECTION YET. CODE STILL ON APPROVAL.*/
                        
                    }else{
                        //Error Sequence
                        isError = true;
                        String errorMsg = '';
                        
                        for(Database.error er : lcr.getErrors()){
                            errorMsg += 'Error Message: ' + er.getMessage() + ';';
                        }
                        errorMap.get(payload)[0] = 'Error';
                        errorMap.get(payload)[1] = 'Error when Converting Lead: ' + errorMsg;
                    }
                }
                
                if(!oppByConId.isEmpty()){
                    //Update the Opportunities Names
                    //Previously, Opp.Name was populated with Lead.Company, now add the Contact.Name + Opp.Package_Number__c
                    for(Contact con : [SELECT Id, Name FROM Contact WHERE Id IN :oppByConId.keySet()]){
                        String packageNumber = '';
                        if(oppByConId.get(con.Id).Package_Number__c!=null){
                            packageNumber = oppByConId.get(con.Id).Package_Number__c;
                        }
                        oppByConId.get(con.Id).Name += ' ' + con.Name + ' ' + packageNumber;
                    }
                }
                
                //Update the Opportunities. If any throw an Error, we added to its ErrorMap.
                if(!opp2Upd.isEmpty()){
                    List<Database.SaveResult> srOppList = Database.update(opp2Upd, false);
                    
                    for(Integer i=0; i < opp2Upd.size(); i++){
                        String payload = payloadByOppId.get(opp2Upd[i].Id);
                        Database.SaveResult sr = srOppList[i];
                        
                        if(!sr.isSuccess()){
                            isError = true;
                            String errorMsg = '';
                            
                            for(Database.error er : sr.getErrors()){
                                errorMsg += 'Error Message: ' + er.getMessage() + ';';
                            }
                            errorMsg = 'DML Error when Updating Opportunity: ' + errorMsg;
                            
                            errorMap.get(payload)[0] = 'Error';
                            
                            if(errorMap.get(payload)[1] != ''){
                                errorMsg = ' | ' + errorMsg;
                            }
                            errorMap.get(payload)[1] += errorMsg;
                        }
                    }
                    List<OpportunityContactRole> ocr2upd = new List<OpportunityContactRole>();
                    for(OpportunityContactRole ocr : [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :payloadByOppId.keySet() LIMIT 1]){
                        ocr.IsPrimary = true;
                        ocr2upd.add(ocr);
                    }
                    
                    if(!ocr2upd.isEmpty()){
                        update ocr2upd;
                    }
                }
                
                //Update the Contacts. If any throw an Error, we added to its ErrorMap.
                if(!con2Upd.isEmpty()){
                    List<Database.SaveResult> srConList = Database.update(con2Upd, false);
                    
                    for(Integer i=0; i < con2Upd.size(); i++){
                        for(String payload : payloadByConId.get(con2Upd[i].Id)){
                            Database.SaveResult sr = srConList[i];
                            
                            if(!sr.isSuccess()){
                                isError = true;
                                String errorMsg = '';
                                
                                for(Database.error er : sr.getErrors()){
                                    errorMsg += 'Error Message: ' + er.getMessage() + ';';
                                }
                                errorMsg = 'DML Error when Updating Contact: ' + errorMsg;
                                
                                errorMap.get(payload)[0] = 'Error';
                                
                                if(errorMap.get(payload)[1] != ''){
                                    errorMsg = ' | ' + errorMsg;
                                }
                                errorMap.get(payload)[1] += errorMsg;
                            }
                        }
                    }
                }
                
                //Update the Accounts. If any throw an Error, we added to its ErrorMap.
                if(!acc2Upd.isEmpty()){
                    List<Database.SaveResult> srAccList = Database.update(acc2Upd, false);
                    
                    for(Integer i=0; i < acc2Upd.size(); i++){
                        for(String payload : payloadByAccId.get(acc2Upd[i].Id)){
                            Database.SaveResult sr = srAccList[i];
                            
                            if(!sr.isSuccess()){
                                isError = true;
                                String errorMsg = '';
                                
                                for(Database.error er : sr.getErrors()){
                                    errorMsg += 'Error Message: ' + er.getMessage() + ';';
                                }
                                errorMsg = 'DML Error when Updating Account: ' + errorMsg;
                                
                                errorMap.get(payload)[0] = 'Error';
                                
                                if(errorMap.get(payload)[1] != ''){
                                    errorMsg = ' | ' + errorMsg;
                                }
                                errorMap.get(payload)[1] += errorMsg;
                            }
                        }
                    }
                }
            //}
            system.debug('errorMap: ' + errorMap);
            xmlResponse = '';
            csvResponse = '"Payload","Status","Commited","Description","LeadId","OpportunityId","ContactId","AccountId","Time"\n';
            //Create the xml Response.
            for(String payload : sortedPayload){
                String status = errorMap.get(payload)[0];
                String description = errorMap.get(payload)[1];
                String leadId = errorMap.get(payload)[2];
                String oppId = errorMap.get(payload)[3];
                String conId = errorMap.get(payload)[4];
                String accId = errorMap.get(payload)[5];
                
                xmlResponse += '<NewLead payloadid="'+payload+'" leadid="'+leadId+'" opportunityid="'+oppId+'" contactid="'+conId+'" accountid="'+accId+'" ';
                
                xmlResponse += 'status="'+status+'" description="'+description+'" commited="changethisvalueforiserror"/>';
                
                if( status.equalsIgnoreCase('Error') ){
                    isError = true;
                }
                
                csvResponse += '"'+payload+'","'+status+'","changethisvalueforiserror","'+description+'","'+leadId+'","'+oppId+'","'+conId+'","'+accId+'","'+system.now()+'"\n';
            }
            
            xmlResponse = xmlResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            csvResponse = csvResponse.replaceAll('changethisvalueforiserror', String.valueOf(!isError));
            
            if(!isError){
                xmlResponse = '<response><status code="200" description=""><NewLeads>' + xmlResponse;
            }else{
                xmlResponse = '<response><status code="500" description="Errors were produced while inserting/updating records, please refer to the result records to see the detailed error messages. None of these records was committed to the database."><NewLeads>' + xmlResponse;
                if(!Test.isRunningTest()){
                    //If any error has ocurrer, then RollBack Database
                    Database.rollback(sp);
                }
                SendEmail('FullRegistrationFlow', 'SAAS Registration Process Completed with Errors', csvResponse);
            }
            xmlResponse += '</NewLeads></status></response>';
            
        }catch(Exception e){
            String result = CatchProcessing(e);
            
            Database.rollback(sp);
            
            xmlResponse = '<response><status code="500" description="' + result + '" /></response>';
        }
        
        return xmlResponse;
    }
    
    static public String CatchProcessing(Exception e){
        //In case of an error, assemble the xmlResponse - code 500 = Failure, include the error message
        String errorMsg = e.getMessage();
        errorMsg += '\nStack Trace:' + e.getStackTraceString();
        errorMsg += '\nLine Number:' + e.getLineNumber();
        errorMsg += '\nException Type:' + e.getTypeName();            
        System.debug('errorMsg: ' + errorMsg);
        
        String result = e.getMessage();
        if(result.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            Integer lastIndex = result.length();
            if(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') < result.lastIndexOf(':')){
                lastIndex = result.lastIndexOf(':');
            }
            result = result.substring(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length()+2, lastIndex);
        }
        System.debug(e.getMessage());
        
        return result + errorMsg;
    }
    
    static private void SendEmail(String csvName, String emailSubject, String csvResponse){
        List<Messaging.Emailfileattachment> emailAttachments = new List<Messaging.Emailfileattachment>();
        Messaging.Emailfileattachment efa2 = new Messaging.Emailfileattachment();
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        
        efa2.setBody(Blob.valueOf(csvResponse));
        efa2.setFileName('SalesProcessWS-'+csvName+'-Response.csv');        
        emailAttachments.add(efa2);
        
        mail.setSaveAsActivity(false);
        mail.setFileAttachments(emailAttachments);
        mail.setSubject(emailSubject);           
        mail.setPlainTextBody('Errors were produced while inserting/updating records, please refer to the result records in the attached csv to see the detailed error messages. None of these records was committed to the database.');
        
        if(UserInfo.getOrganizationId().contains('00DM000000059tlMAA') ){ // is sandbox
            mail.setToAddresses(new List<String>{'hadas@service-wise.com', 'hernansinclair@gmail.com'});            
        }else{
            mail.setToAddresses(new List<String>{'daveh@checkmarx.com'});
            mail.setCcAddresses(new List<String>{'itay@service-wise.com', 'hernansinclair@gmail.com'}); 
        }
        
        if(!Test.isRunningTest()){
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.Email[] { mail }); 
        }
    }
    
    static private String mandatoryFieldsCheck(List<String> mandatoryFields, Set<String> keyFields){
        String result='';
        if(mandatoryFields != null && !mandatoryFields.isEmpty()){
            for(String fName : mandatoryFields){
                if(!keyFields.contains(fName) ){
                    result += '['+fName+']';
                }
            }
            if(result!=''){
                result = 'Missing mandatory fields: ' + result;
            }
        }
        return result;
    }
    
    static private String setField(sObject sObj, String fName, Map<String, String> fieldType, String fValue ){
        //This method tries to convert the given value to the dataType of the field it is saved uppon. It also saves it on the object
        //If it fails, return a string with the Error.
        String result = '';
        try{
            String fTypeName = fieldType.get(fName);
            //Format it to the proper type
            if(fValue <> ''){
                if(fTypeName.equalsIgnoreCase('datetime')){
                    sObj.put(fName, Datetime.valueOf(fValue));
                }else if(fTypeName.equalsIgnoreCase('date')){
                    sObj.put(fName, date.valueOf(fValue));
                }else if(fTypeName.equalsIgnoreCase('boolean')){
                    sObj.put(fName, Boolean.valueOf(fValue));
                }else if(fTypeName.equalsIgnoreCase('integer')){
                    sObj.put(fName, Integer.valueOf(fValue));
                }else if(fTypeName.equalsIgnoreCase('double') || fTypeName.equalsIgnoreCase('currency') || fTypeName.equalsIgnoreCase('percent')){
                    sObj.put(fName, Double.valueOf(fValue));
                }else if(fTypeName.equalsIgnoreCase('decimal')){
                    sObj.put(fName, Decimal.valueOf(fValue));
                }else{
                    sObj.put(fName, fValue);
                }
            }
        }catch(Exception e){
            result = e.getMessage();
            if(result.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                Integer lastIndex = result.length();
                if(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') < result.lastIndexOf(':')){
                    lastIndex = result.lastIndexOf(':');
                }
                result = result.substring(result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length()+2, lastIndex);
            }
            System.debug(e.getMessage());
        }
        return result;
    }
    
    static testmethod void UpdateUsageDetails_Test01(){
    	
    	SalesProcessWS.BuildCustomSettingForTesting();
    	ClsObjectCreator cls = new ClsObjectCreator();

    	//Create some custom settings that are bound to fail
    	List<SalesProcessMappingField__c> csList = new List<SalesProcessMappingField__c>();
    	
    	csList.add(new SalesProcessMappingField__c(Name='Opportunity_BadField', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'BadField'));
    	csList.add(new SalesProcessMappingField__c(Name='Opportunity_NoField', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = ''));
    	
    	insert csList;
    	
        Account acc1 = cls.returnAccount('My Test Account 1234');
        insert acc1; 

        Contact con1 = cls.returnContact(acc1.ID , 'Test01@test.com');
        con1.Username__c='test01';
        Contact con2 = cls.returnContact(acc1.ID , 'Test02@test.com');
        con2.Username__c='test02';
        Contact con3 = cls.returnContact(acc1.ID , 'Test03@test.com');
        con3.Username__c='test03';
        Contact con4 = cls.returnContact(acc1.ID , 'Test04@test.com');
        con4.Username__c='test04';
        Contact con5 = cls.returnContact(acc1.ID , 'Test05@test.com');
        con4.Username__c='test05';
        Contact con6 = cls.returnContact(acc1.ID , 'Test06@test.com');
        con4.Username__c='test06';

        insert new List<Contact>{con1,con2, con3, con4, con5};
        //Id SAASRecordType = Schema.sObjectType.Opportunity.getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
        Id SAASRecordType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='SAAS - redundant' LIMIT 1].ID;
        //Id SAASRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('SAAS').getRecordTypeId();


        //Opportunity opp1 = new Opportunity(Name = 'My Test Opp 1', AccountId = acc1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', Primary_Contact__c = con1.Id, RecordTypeId = SAASRecordType);
        //Opportunity opp2 = new Opportunity(Name = 'My Test Opp 2', AccountId = acc1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', Primary_Contact__c = con2.Id, RecordTypeId = SAASRecordType);
        //Opportunity opp3 = new Opportunity(Name = 'My Test Opp 3', AccountId = acc1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', Primary_Contact__c = con3.Id, RecordTypeId = SAASRecordType);
        //Opportunity opp4 = new Opportunity(Name = 'My Test Opp 4', AccountId = acc1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', Primary_Contact__c = con4.Id, RecordTypeId = SAASRecordType);
        //Opportunity opp5 = new Opportunity(Name = 'My Test Opp 5', AccountId = acc1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', Primary_Contact__c = con5.Id, RecordTypeId = SAASRecordType);
        //insert new List<Opportunity>{opp1, opp2, opp3, opp4, opp5};
        /*
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = con1.Id, OpportunityId = opp1.Id, Role = 'Other');
        OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId = con2.Id, OpportunityId = opp2.Id, Role = 'Other');
        OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId = con3.Id, OpportunityId = opp3.Id, Role = 'Other');
        insert new List<OpportunityContactRole>{ocr1, ocr2, ocr3};
        */
        
        /*
        <Request>
          <Opportunities>
            <Opportunity payloadid="" username="">
              <Field field-name="" value=""/>
            </Opportunity>
          </Opportunities>
        </Request>
        */
        String xmlRequest = '<request> <Opportunities>';
        
        xmlRequest += '<Opportunity payloadid="001" username="test01">';
            xmlRequest += '<Field field-name="Opportunity_Name" value="test01" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
            xmlRequest += '<Field field-name="Opportunity_First_login_Date__c" value="2012-10-01" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Login_Date__c" value="2012-10-02" />';
			xmlRequest += '<Field field-name="Opportunity_First_Scan_Date__c" value="2012-10-03" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Scan_Date__c" value="2012-10-04" />';
			xmlRequest += '<Field field-name="Opportunity_Total_Scans__c" value="10" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="002" username="test02">';
            xmlRequest += '<Field field-name="Opportunity_Name" value="test02" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
            xmlRequest += '<Field field-name="Opportunity_First_login_Date__c" value="2012-10-05" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Login_Date__c" value="2012-10-06" />';
			xmlRequest += '<Field field-name="Opportunity_First_Scan_Date__c" value="2012-10-07" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Scan_Date__c" value="2012-10-08" />';
			xmlRequest += '<Field field-name="Opportunity_Total_Scans__c" value="20" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="003" username="test03">';
            xmlRequest += '<Field field-name="Opportunity_Name2" value="test03" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
            xmlRequest += '<Field field-name="Opportunity_First_login_Date__c" value="2012-10-09" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Login_Date__c" value="2012-10-10" />';
			xmlRequest += '<Field field-name="Opportunity_First_Scan_Date__c" value="2012-10-11" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Scan_Date__c" value="2012-10-12" />';
			xmlRequest += '<Field field-name="Opportunity_Total_Scans__c" value="30" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="004" username="test04">';
            xmlRequest += '<Field field-name="Opportunity_BadField" value="test04" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
            xmlRequest += '<Field field-name="Opportunity_First_login_Date__c" value="2012-10-13" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Login_Date__c" value="2012-10-14" />';
			xmlRequest += '<Field field-name="Opportunity_First_Scan_Date__c" value="2012-10-15" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Scan_Date__c" value="2012-10-16" />';
			xmlRequest += '<Field field-name="Opportunity_Total_Scans__c" value="40" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="005" username="test05">';
            xmlRequest += '<Field field-name="Opportunity_NoField" value="test05" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
            xmlRequest += '<Field field-name="Opportunity_First_login_Date__c" value="2012-10-17" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Login_Date__c" value="2012-10-18" />';
			xmlRequest += '<Field field-name="Opportunity_First_Scan_Date__c" value="2012-10-19" />';
			xmlRequest += '<Field field-name="Opportunity_Last_Scan_Date__c" value="2012-10-20" />';
			xmlRequest += '<Field field-name="Opportunity_Total_Scans__c" value="50" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="006" username="test06">';
            xmlRequest += '<Field field-name="Opportunity_NoField" value="test06" />';
            xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += ' </Opportunities> </request>';
        
        String response = SalesProcessWS.UpdateUsageDetails(xmlRequest);
        system.debug('Response:' + response);
        
        //system.assertEquals('test01', [SELECT Name FROM Opportunity WHERE Id =:opp1.Id LIMIT 1][0].Name);
        //system.assertEquals('test02', [SELECT Name FROM Opportunity WHERE Id =:opp2.Id LIMIT 1][0].Name);
        //system.assertEquals('My Test Opp 3', [SELECT Name FROM Opportunity WHERE Id =:opp3.Id LIMIT 1][0].Name);
        //system.assertEquals('My Test Opp 4', [SELECT Name FROM Opportunity WHERE Id =:opp4.Id LIMIT 1][0].Name);
        //system.assertEquals('My Test Opp 5', [SELECT Name FROM Opportunity WHERE Id =:opp5.Id LIMIT 1][0].Name);
        
        
        SalesProcessWS.SalesProcessWSException error = new SalesProcessWS.SalesProcessWSException('error');
        SalesProcessWS.CatchProcessing(error);
    }
    
    static testmethod void RenewalUpgradeDowngradeFlow_Test01(){

        ClsObjectCreator cls = new ClsObjectCreator();

        Account acc1 = cls.returnAccount('My Test Account 4321');
        insert acc1;
        
        Contact con1 = cls.returnContact(acc1.ID , 'Test07@test.com');
        con1.Username__c='test01';
        Contact con2 = cls.returnContact(acc1.ID , 'Test08@test.com');
        con2.Username__c='test02';
        Contact con3 = cls.returnContact(acc1.ID , 'Test09@test.com');
        con3.Username__c='test03';
        Contact con4 = cls.returnContact(acc1.ID , 'Test10@test.com');
        con4.Username__c='test04';

        insert new List<Contact>{con1,con2, con3, con4};
        Id SAASRecordType = [SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND Name='SAAS - redundant' LIMIT 1].ID;
        //Id SAASRecordType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('SAAS').getRecordTypeId();
        
        //Opportunity opp1 = new Opportunity(Name = 'My Test Opp 1', AccountId = acc1.Id, Primary_Contact__c = con1.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', RecordTypeId = SAASRecordType);
        //Opportunity opp2 = new Opportunity(Name = 'My Test Opp 2', AccountId = acc1.Id, Primary_Contact__c = con2.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', RecordTypeId = SAASRecordType);
        //Opportunity opp3 = new Opportunity(Name = 'My Test Opp 3', AccountId = acc1.Id, Primary_Contact__c = con3.Id, CloseDate = System.today().addDays(2), StageName = 'Demo', RecordTypeId = SAASRecordType);
        //insert new List<Opportunity>{opp1, opp2, opp3};
        /*
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = con1.Id, OpportunityId = opp1.Id, Role = 'Other');
        OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId = con2.Id, OpportunityId = opp2.Id, Role = 'Other');
        OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId = con3.Id, OpportunityId = opp3.Id, Role = 'Other');
        insert new List<OpportunityContactRole>{ocr1, ocr2, ocr3};
        */
        
        /*
        <Request>
          <Opportunities>
            <Opportunity payloadid="" username="">
              <Field field-name="" value=""/>
            </Opportunity>
          </Opportunities>
        </Request>
        */
        String xmlRequest = '<request> <Opportunities> ';
        
        xmlRequest += '<Opportunity payloadid="001" username="test01">';
            xmlRequest += '<Field field-name="Name" value="test01" />';
            xmlRequest += '<Field field-name="StageName" value="Demo" />';
            xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '<Field field-name="Package_Number__c" value="PN01" />';
            xmlRequest += '<Field field-name="CloseDate" value="' +system.today()+ '" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="002" username="test02">';
            xmlRequest += '<Field field-name="Name" value="test02" />';
            xmlRequest += '<Field field-name="StageName" value="Demo" />';
            xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '<Field field-name="Package_Number__c" value="PN02" />';
            xmlRequest += '<Field field-name="CloseDate" value="' +system.today()+ '" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="003" username="test03">';
            xmlRequest += '<Field field-name="Name" value="test03" />';
            xmlRequest += '<Field field-name="Package_Number__c" value="PN03" />';
            xmlRequest += '<Field field-name="CloseDate" value="' +system.today()+ '" />';
            xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="004" username="test04">';
            xmlRequest += '<Field field-name="Name" value="test04" />';
            xmlRequest += '<Field field-name="StageName" value="Demo" />';
            xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '<Field field-name="Package_Number__c" value="PN04" />';
            xmlRequest += '<Field field-name="CloseDate" value="' +system.today()+ '" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += '<Opportunity payloadid="005" username="test05">';
            xmlRequest += '<Field field-name="Name" value="test05" />';
            xmlRequest += '<Field field-name="StageName" value="Demo" />';
            xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '<Field field-name="Package_Number__c" value="PN05" />';
            xmlRequest += '<Field field-name="CloseDate" value="' +system.today()+ '" />';
        xmlRequest += '</Opportunity>';
        
        xmlRequest += ' </Opportunities> </request>';
        
        String result = SalesProcessWS.RenewalUpgradeDowngradeFlow(xmlRequest);
        
        system.debug('RenewalUpgradeDowngradeFlow_Result:' + result);
        
        //system.assertEquals('Closed Won', [SELECT StageName FROM Opportunity WHERE Id =:opp1.Id LIMIT 1][0].StageName);
        //system.assertEquals('Closed Won', [SELECT StageName FROM Opportunity WHERE Id =:opp2.Id LIMIT 1][0].StageName);
    }
    
    private static void BuildCustomSettingForTesting(){
    	if(system.Test.isRunningTest()){
    		delete [SELECT Id FROM SalesProcessMappingField__c];
	    	
	    	List<SalesProcessMappingField__c> cs2Ins = new List<SalesProcessMappingField__c>();
	    	
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Lead_LastName', SF_Object_API_Name__c = 'Lead', SF_Field_API_Name__c = 'LastName'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Lead_Company', SF_Object_API_Name__c = 'Lead', SF_Field_API_Name__c = 'Company'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Lead_Username__c', SF_Object_API_Name__c = 'Lead', SF_Field_API_Name__c = 'Username__c'));
	    	
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Name', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Name'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_StageName', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'StageName'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Package_Number__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Package_Number__c'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Amount', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Amount'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Expiration_Date__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Expiration_Date__c'));
	    	
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_First_Login_Date__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'First_Login_Date__c'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Last_Login_Date__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Last_Login_Date__c'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_First_Scan_Date__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'First_Scan_Date__c'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Last_Scan_Date__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Last_Scan_Date__c'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Opportunity_Total_Scans__c', SF_Object_API_Name__c = 'Opportunity', SF_Field_API_Name__c = 'Total_Scans__c'));
	    	
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Contact_LastName', SF_Object_API_Name__c = 'Contact', SF_Field_API_Name__c = 'LastName'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Contact_Email', SF_Object_API_Name__c = 'Contact', SF_Field_API_Name__c = 'Email'));
	    	
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Account_Name', SF_Object_API_Name__c = 'Account', SF_Field_API_Name__c = 'Name'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Account_Industry', SF_Object_API_Name__c = 'Account', SF_Field_API_Name__c = 'Industry'));
	    	cs2Ins.add( new SalesProcessMappingField__c(Name='Account_Type', SF_Object_API_Name__c = 'Account', SF_Field_API_Name__c = 'Type'));
	    	
	    	
	    	insert cs2Ins;
    	}
    }
    
    static testmethod void FullRegistrationFlow_Test01(){
    	SalesProcessWS.BuildCustomSettingForTesting();
    	ClsObjectCreator cls = new ClsObjectCreator();
    	//STEP 1
        Lead ld1 = cls.returnLead('Test03@test.com');
        ld1.LastName='FullRegistrationFlow02';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='FullRegistrationFlow02';
        ld1.Email = 'FullRegistrationFlow02@test.com';

        insert ld1;
    	
    	String xmlRequest = '<Request><NewLeads>';
        //Lead doesn't exist
        xmlRequest += '<NewLead payloadid="001">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="FullRegistrationFlow01" />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow01" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="false" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Lead exist
        xmlRequest += '<NewLead payloadid="002">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="FullRegistrationFlow02" />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow02" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow02@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="false" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        xmlRequest += '</NewLeads></Request>';
        
        String result = SalesProcessWS.FullRegistrationFlow(xmlRequest);
        
        //system.assertEquals( 2, [SELECT Id FROM Lead WHERE LastName = 'FullRegistrationFlow01' OR LastName = 'FullRegistrationFlow02' ].size() );
        
        //ld1 = [SELECT Saas__c FROM Lead WHERE Id = :ld1.Id LIMIT 1][0];
        //system.assertEquals(true, ld1.Saas__c);
    }
    
    static testmethod void FullRegistrationFlow_Test02(){
    	SalesProcessWS.BuildCustomSettingForTesting();
        ClsObjectCreator cls = new ClsObjectCreator();
    	//STEP 2
    	
    	Account acc1 = cls.returnAccount('FullRegistrationFlow01');
        Account acc4 = cls.returnAccount('Test04');
        Account acc5 = cls.returnAccount('Test05');
        insert new List<Account>{acc1,acc4,acc5};
        
        Contact con1 = cls.returnContact(acc1.ID , 'Test11@test.com');
        con1.Email = 'Test01@test.com';
        Contact con4 = cls.returnContact(acc4.ID , 'Test12@test.com');
        con4.Email = 'FullRegistrationFlow02@test.com';
        insert new List<Contact>{con1, con4};
        
        Lead ld1 = cls.returnLead('Test04@test.com');
        ld1.LastName='FullRegistrationFlow01';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='FullRegistrationFlow01';
        ld1.Email = 'FullRegistrationFlow01@test.com';

        Lead ld2 = cls.returnLead('Test05@test.com');
        ld2.LastName='FullRegistrationFlow03';
        ld2.Customer_Type__c = 'SAAS';
        ld2.Company='FullRegistrationFlow02';
        ld2.Email = 'FullRegistrationFlow03@test.com';

    	insert new List<Lead>{ld1, ld2};
    	
    	String xmlRequest = '<Request><NewLeads>';
        //Lead exist
        xmlRequest += '<NewLead payloadid="001">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="FullRegistrationFlow01" />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow01" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Lead exist
        xmlRequest += '<NewLead payloadid="002">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="FullRegistrationFlow02" />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow02" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow02@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        xmlRequest += '</NewLeads></Request>';
        
        String result = SalesProcessWS.FullRegistrationFlow(xmlRequest);
        
        //system.assertEquals(1, [SELECT Id FROM Lead WHERE (Id=:ld1.Id OR Id=:ld2.Id) AND IsConverted=true ].Size());
        
        //system.assertEquals( 1, [SELECT Id FROM Opportunity WHERE AccountId = :acc4.Id ].size() );
        //system.assertEquals( 1 ,[SELECT Id FROM Opportunity WHERE AccountId = :acc1.Id ].size() );
    }
    
    static testmethod void FullRegistrationFlow_Test03(){
    	SalesProcessWS.BuildCustomSettingForTesting();
    	ClsObjectCreator cls = new ClsObjectCreator();

    	//Create some custom settings that are bound to fail
    	List<SalesProcessMappingField__c> csList = new List<SalesProcessMappingField__c>();
    	
    	csList.add(new SalesProcessMappingField__c(Name='Lead_BadField', SF_Object_API_Name__c = 'Lead', SF_Field_API_Name__c = 'BadField'));
    	csList.add(new SalesProcessMappingField__c(Name='Lead_NoObject', SF_Object_API_Name__c = '', SF_Field_API_Name__c = 'Username__c'));
    	csList.add(new SalesProcessMappingField__c(Name='Lead_NoField', SF_Object_API_Name__c = 'Lead', SF_Field_API_Name__c = ''));
    	
    	insert csList;
    	
    	//Negative tests
    	Account acc1 = cls.returnAccount('Test043');
        Account acc4 = cls.returnAccount('Test042');
        Account acc5 = cls.returnAccount('Test035');

        insert new List<Account>{acc1,acc4,acc5};
        
        Contact con1 = cls.returnContact(acc1.ID , 'Test14@test.com');
        con1.Email = 'Test01@test.com';
        Contact con4 = cls.returnContact(acc4.ID , 'Test15@test.com');
        con4.Email = 'Test04@test.com';

        insert new List<Contact>{con1, con4};
        

        Lead ld1 = cls.returnLead('Test06@test.com');
        ld1.LastName='Test01';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='Test01';
        ld1.Email = 'Test01test.com';

        Lead ld2 = cls.returnLead('Test07@test.com');
        ld1.LastName='Test04';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='Test04';
        ld1.Email = 'Test04@test.com';

        Lead ld3 = cls.returnLead('Test08@test.com');
        ld1.LastName='Test07';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='Test07';
        ld1.Email = 'Test07@test.com';

    	insert new List<Lead>{ld1, ld2, ld3};
    	
    	String xmlRequest = '<Request><NewLeads>';
    	//Bad insert lead (ej:no fields)
        xmlRequest += '<NewLead payloadid="004">';
            //xmlRequest += '<Object name="Lead">';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test04" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN04" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="4" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test04" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test04@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test04" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Bad field in Lead AND No Custom Field for Opportunity
        xmlRequest += '<NewLead payloadid="005">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_Company" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_BadField" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN05" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="5" />';
                xmlRequest += '<Field field-name="Opportunity_NoMappingField" value="5" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Bad Custom Setting - No Object
        xmlRequest += '<NewLead payloadid="005">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_Company" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_NoObject" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN05" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="5" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Bad Custom Setting - No Field Assigned
        xmlRequest += '<NewLead payloadid="005">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_Company" value="Test05" />';
                xmlRequest += '<Field field-name="Lead_NoField" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN05" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="5" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test05@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test05" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //NO LEAD!!!
        xmlRequest += '<NewLead payloadid="006">';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test06" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN06" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="6" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test06" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test06@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test06" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Error updating Opportunity/Contact/Account
        xmlRequest += '<NewLead payloadid="007">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value="Test07" />';
                xmlRequest += '<Field field-name="Lead_Company" value="Test07" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="Test07@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="  " />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN07" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="7" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="abc" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="  " />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test07@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="  " />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="true" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        xmlRequest += '</NewLeads></Request>';
        
        String result = SalesProcessWS.FullRegistrationFlow(xmlRequest);
        
        system.debug('FullRegistrationFlow_Result:' + result);
    }
    
    static testmethod void FullRegistrationFlow_Test04(){
    	SalesProcessWS.BuildCustomSettingForTesting();

    	ClsObjectCreator cls = new ClsObjectCreator();
    	//Negative Tests
    	
    	//STEP 1
    	Lead ld1 = cls.returnLead('Test09@test.com');
        ld1.LastName='FullRegistrationFlow02';
        ld1.Customer_Type__c = 'SAAS';
        ld1.Company='FullRegistrationFlow02';
        ld1.Email = 'FullRegistrationFlow02@test.com';

    	insert ld1;
    	
    	String xmlRequest = '<Request><NewLeads>';
        //Lead doesn't exist
        xmlRequest += '<NewLead payloadid="001">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value=" " />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow01" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="false" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Lead exist
        xmlRequest += '<NewLead payloadid="002">';
            //xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="Lead_LastName" value=" " />';
                xmlRequest += '<Field field-name="Lead_Company" value="FullRegistrationFlow02" />';
                xmlRequest += '<Field field-name="Lead_Username__c" value="FullRegistrationFlow02@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Opportunity_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Opportunity_StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Opportunity_Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Opportunity_Amount" value="1" />';
                xmlRequest += '<Field field-name="Opportunity_Expiration_Date__c" value="' +system.today()+ '" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="Contact_LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Contact_Email" value="Test01@test.com" />';
            //xmlRequest += '</Object>';
            //xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Account_Name" value="Test01" />';
                xmlRequest += '<Field field-name="Account_Industry" value="Other" />';
                xmlRequest += '<Field field-name="Account_Type" value="Analyst" />';
                
                xmlRequest += '<Field field-name="Active" value="false" />';
            //xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        xmlRequest += '</NewLeads></Request>';
        
        String result = SalesProcessWS.FullRegistrationFlow(xmlRequest);
    }
    /*
    static testmethod void FullRegistrationFlow_Test01_OLD(){
        /*
        Lead ld1 = new Lead(LastName='L1', Company='Test Account 1', Email = 'test1@test.com');
        Lead ld2 = new Lead(LastName='L2', Company='Test Account 2', Email = 'test1@test.com');
        Lead ld3 = new Lead(LastName='L3', Company='Test Account 1');
        Lead ld4 = new Lead(LastName='L4', Company='Test Account 3');
        List<Lead> leadList = new List<Lead>{ld1,ld2,ld3,ld4};
        Phase1.IsFullRegistrationFlow = true;
        insert leadList;
        */
        /*
        Account acc1 = new Account(Name='Test01');
        Account acc4 = new Account(Name='Test04');
        Account acc5 = new Account(Name='Test05');
        insert new List<Account>{acc1,acc4,acc5};
        
        Contact con1 = new Contact(LastName='Test01', Email = 'Test01@test.com', AccountId = acc1.Id, Customer_Type__c = 'Other');
        Contact con4 = new Contact(LastName='Test04', Email = 'Test04@test.com', AccountId = acc4.Id, Customer_Type__c = 'Other');
        insert new List<Contact>{con1, con4};
        /*
        Map<Id,Lead> leadMap = new Map<Id,Lead>();
        for(Lead l : leadList){
            leadMap.put(l.Id,l);
        }
        */
        /*
        <Request>
          <NewLeads>
            <NewLead payloadid="">
              <Object name="">
                  <Field field-name="" value=""/>
              </Object>
              <Object name="">
                  <Field field-name="" value=""/>
              </Object>
            </NewLead>
          </NewLeads>
        </Request>
        */
        /*
        String xmlRequest = '<Request><NewLeads>';
        //Finds Contact
        xmlRequest += '<NewLead payloadid="001">';
            xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Company" value="Test01" />';
                xmlRequest += '<Field field-name="Username__c" value="Test01@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test01" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN01" />';
                xmlRequest += '<Field field-name="Amount" value="1" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test01" />';
                xmlRequest += '<Field field-name="Email" value="Test01@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test01" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Not Finds Contact, Finds Account
        xmlRequest += '<NewLead payloadid="002">';
            xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="LastName" value="Test02" />';
                xmlRequest += '<Field field-name="Company" value="Test04" />';
                xmlRequest += '<Field field-name="Username__c" value="Test02@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test02" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN02" />';
                xmlRequest += '<Field field-name="Amount" value="2" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test02" />';
                xmlRequest += '<Field field-name="Email" value="Test02@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test02" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Not Finds Contact, Not Finds Account
        xmlRequest += '<NewLead payloadid="003">';
            xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="LastName" value="Test03" />';
                xmlRequest += '<Field field-name="Company" value="Test03" />';
                xmlRequest += '<Field field-name="Username__c" value="Test03@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test03" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN03" />';
                xmlRequest += '<Field field-name="Amount" value="3" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test03" />';
                xmlRequest += '<Field field-name="Email" value="Test03@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test03" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Bad insert lead (ej:no fields)
        xmlRequest += '<NewLead payloadid="004">';
            xmlRequest += '<Object name="Lead">';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test04" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN04" />';
                xmlRequest += '<Field field-name="Amount" value="4" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test04" />';
                xmlRequest += '<Field field-name="Email" value="Test04@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test04" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Bad field in Lead
        xmlRequest += '<NewLead payloadid="005">';
            xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Company" value="Test05" />';
                xmlRequest += '<Field field-name="BadField" value="Test05@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test05" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN05" />';
                xmlRequest += '<Field field-name="Amount" value="5" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test05" />';
                xmlRequest += '<Field field-name="Email" value="Test05@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test05" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //NO LEAD!!!
        xmlRequest += '<NewLead payloadid="006">';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="Test06" />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN06" />';
                xmlRequest += '<Field field-name="Amount" value="6" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="Test06" />';
                xmlRequest += '<Field field-name="Email" value="Test06@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="Test06" />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        //Error updating Opportunity/Contact/Account
        xmlRequest += '<NewLead payloadid="007">';
            xmlRequest += '<Object name="Lead">';
                xmlRequest += '<Field field-name="LastName" value="Test07" />';
                xmlRequest += '<Field field-name="Company" value="Test07" />';
                xmlRequest += '<Field field-name="Username__c" value="Test07@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Opportunity">';
                xmlRequest += '<Field field-name="Name" value="  " />';
                xmlRequest += '<Field field-name="StageName" value="Demo" />';
                xmlRequest += '<Field field-name="Package_Number__c" value="PN07" />';
                xmlRequest += '<Field field-name="Amount" value="7" />';
                xmlRequest += '<Field field-name="expiration_date__c" value="' +system.today()+ '" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Contact">';
                xmlRequest += '<Field field-name="LastName" value="  " />';
                xmlRequest += '<Field field-name="Email" value="Test07@test.com" />';
            xmlRequest += '</Object>';
            xmlRequest += '<Object name="Account">';
                xmlRequest += '<Field field-name="Name" value="  " />';
                xmlRequest += '<Field field-name="Industry" value="Other" />';
                xmlRequest += '<Field field-name="Type" value="Analyst" />';
            xmlRequest += '</Object>';
        xmlRequest += '</NewLead>';
        
        xmlRequest += '</NewLeads></Request>';
        
        String result = SalesProcessWS.FullRegistrationFlow(xmlRequest);
        
        system.debug('FullRegistrationFlow_Result:' + result);
        
        system.assertEquals('Test01@test.com', [SELECT Username__c FROM Contact WHERE Id =:con1.Id LIMIT 1][0].Username__c);
        
        system.assertEquals( 1, [SELECT Id FROM Opportunity WHERE AccountId = :acc4.Id ].size() );
        system.assertEquals( 1 ,[SELECT Id FROM Opportunity WHERE AccountId = :acc1.Id ].size() );
        
    }*/
}