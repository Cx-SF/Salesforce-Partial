({
    validateEmail : function(email) {
        var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email));
        //.toLowerCase()
    },
    isPersonalEmail: function(email){
        var domains = [ "gmail", "yahoo", "hotmail", "walla" ];
        for (var i=0;i<domains.length;i++)
        {
            if (email.substring(email.indexOf("@")+1).toLowerCase().indexOf(domains[i]) >= 0)
            {
                return true;
            }
        }
        return false;
    },
    getLink:function(component){
        var action = component.get("c.getOrgId");
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var orgid= response.getReturnValue();
                orgid=orgid.slice(0, 15) 
                //alert('orgid '+orgid);
                component.set("v.orgid", orgid);
            }
        });
        $A.enqueueAction(action);
        
        var action2 = component.get("c.getDomain");
        action2.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var urlDom= response.getReturnValue();
                urlDom+='/servlet/servlet.WebToCase?encoding=UTF-8';
                //alert('urlDom '+urlDom);
                component.set("v.URL", urlDom);
            }
        });
        $A.enqueueAction(action2);
        
        var action3 = component.get("c.getOrgDomain");
        action3.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var url= response.getReturnValue();
                //  alert('url '+url);
                // alert('url'+url);
                
                url+='/CheckmarxCustomerServiceCommunity/s/home-public-knowledge-base';
                
                // alert('url'+url);
                component.set("v.retURL", url);
            }
        });
        $A.enqueueAction(action3);
        
        
        var action4 = component.get("c.getRecorTypeId");
        var params = {"recordTypeName":component.get("v.RecordTypeName")};
        action4.setParams(params);
        action4.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var recordTypeId= response.getReturnValue();
                console.log('recordTypeId = ' + recordTypeId.substring(0, 15));
                component.set("v.RecordTypeId", recordTypeId.substring(0, 15));
            }
        });
        $A.enqueueAction(action4);
    
        /*
        var action5 = component.get("c.getAccountId");
        var params = {"recordTypeName": component.get("v.RecordTypeName")};
        action5.setParams(params);
        action5.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var AccountId= response.getReturnValue();
                component.set("v.AccountId", AccountId);
                console.log('AccountId = ' + AccountId);
            }
        });
        $A.enqueueAction(action5);
        */
    },
        
    sendEmail:function(component,body){
        //alert(body);
        var action = component.get("c.sendEmail");
        var params = {"body":body};
        action.setParams(params);
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var sucsessSending= response.getReturnValue();
                console.log(sucsessSending);
                //alert(sucsessSending);
            }
        });
        $A.enqueueAction(action);
    }
})