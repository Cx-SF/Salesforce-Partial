({
    // Added by Alex Levchenko on 06-Jun-2019: Start
    
    doInit: function (cmp, evt, helper){
        helper.getLink(cmp);
        var vfOrigin = window.location.origin;
        window.addEventListener("message", function(event) {
            // debugger;
            if (event.origin !== vfOrigin) {
                return;
            } 
            if (event.data.name == "Unlock") {            	
                cmp.set('v.recaptchaResponse', event.data.responseRecaptcha);
                var captchaPair = $A.get("$Label.c.GoogleRecaptchaPair");
                var recaptchaSettings = '{"keyname":"' + captchaPair + '", "fallback":"true", "orgId":"' + cmp.get('v.orgid') + '", "ts":"' + JSON.stringify(new Date().getTime()) + '"}';
				cmp.set('v.recaptchaSettings', recaptchaSettings);
                cmp.set('v.passedCaptcha', true);
            } else {            	
                cmp.set('v.passedCaptcha', false);
            } 
        }, false);          
    },	
    // Added by Alex Levchenko on 06-Jun-2019: End
    
    
    openModel: function(component, event, helper) {
        component.set('v.passedCaptcha', false);
        component.set("v.isOpen", true);  
    },
    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
         component.set("v.endSubmit", false);
        
    },
    
    
    doSubmited : function(component,event,helper){  
        // let emailInput = component.find('email');
        // let subject = component.find('subject');
        let description = component.find('description');  
        let frm=document.getElementById("frm");
        let email = document.getElementById("email").value;//emailInput.get("v.value");
        let communityType = component.get("v.CommunityType");
        //let iframe=component.find('iframe');
        if (email == "" || email == null)
        {
            alert("Email must be entered");
        }
        else
        {
            if (email != ""  && email != null)
            {
                if (helper.validateEmail(email))
                {
                    if (helper.isPersonalEmail(email))
                    {
                        alert("Can not use personal emails");
                    }
                    else
                    {   
                        // emailInput?.set("v.style","display:none");
                        document.getElementById('email').style.display = "none";
                        document.getElementById('emailLabel').style.display = "none";
                        // subject?.set("v.style","display:none");
                        document.getElementById('subject').style.display = "none";
                        document.getElementById('subjectLabel').style.display = "none";
                        description.set("v.style","display:none");
                        //iframe.set("v.style","display:none");
                        component.set("v.endSubmit", true);
                        if(communityType != 'Partner'){
                            //alert(communityType);
                            setTimeout(function(){  frm.submit(); }, 3000);
                            }
                        else{
                            
                            //alert('I am here '+communityType);
                            let body = 'E-mail: '+email+'\n';
                            body+='Subject: '+ document.getElementById("subject").value /*subject.get("v.value")*/+'\n';
                            body+='Description: '+ description.get("v.value")+'\n';
                            helper.sendEmail(component,body);
                            
                        }
                    }
                }
                else
                {
                    alert("Email is not in corrent format");		  
                }
            }
            
        }
    }

})



//var url=window.location.hostname+'/servlet/servlet.WebToCase?encoding=UTF-8';
//component.set("v.URL",url);