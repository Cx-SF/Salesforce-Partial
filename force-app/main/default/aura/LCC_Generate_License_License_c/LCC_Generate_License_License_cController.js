({
doInit : function(cmp, event, helper) {
    var action = cmp.get("c.SendPost");
    action.setParams({
         licId: cmp.get("v.recordId"),
         userId: $A.get( "$SObjectType.CurrentUser.Id" )
    });
    action.setCallback(this, function(response) {
       if (response.getState() === "SUCCESS"){
           var serverResponse = response.getReturnValue();
           cmp.set("v.alert",serverResponse);
           if(serverResponse==''){
               cmp.set("v.succeeded",true);}
       }   
    });
    $A.enqueueAction(action);
},

    itemsChange: function(cmp, evt){
        if(cmp.get("v.currentLicense.HID__c") != null)
        {
            //alert(/^[0-9]+$/.test(cmp.get("v.currentLicense.HID__c").substring(1,cmp.get("v.currentLicense.HID__c").indexOf("_"))));
            if(/^[0-9]+$/.test(cmp.get("v.currentLicense.HID__c").substring(1,cmp.get("v.currentLicense.HID__c").indexOf("_"))))
                cmp.set("v.isHIDnumber1",true);
            if(/^[0-9]+$/.test(cmp.get("v.currentLicense.HID__c").substring(1,cmp.get("v.currentLicense.HID__c").length)))
                cmp.set("v.isHIDnumber0",true);
            if(!(cmp.get("v.currentLicense.HID__c").startsWith("#")) || (cmp.get("v.currentLicense.HID__c").includes("_") && 
               !(cmp.get("v.isHIDnumber1")) || (!(cmp.get("v.currentLicense.HID__c").includes("_")) && !(cmp.get("v.isHIDnumber0")))))
                    cmp.set("v.condition1",true);
        }
        
        if(cmp.get("v.currentLicense.Opp_Support_Status__c") != 'Do NOT Deliver' && !(cmp.get("v.condition1")))
        	$A.enqueueAction(cmp.get('c.doInit'));
    },
    
    accept : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})