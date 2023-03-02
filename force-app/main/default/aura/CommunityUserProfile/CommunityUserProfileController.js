({
    doInit : function(component, event, helper) {
        var profileMenuItems = [
            {itemLabel: 'Home', itemIcon: 'utility:home'},
            {itemLabel: 'Logout', itemIcon: 'utility:logout'}               
        ];
        component.set('v.profileMenuItems', profileMenuItems);
        var action = component.get("c.fetchUserDetail");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set('v.user', res);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Cannot fetch user details: " + errors[0].message);
                    }
                } else {
                    console.error("Unknown error in fetching user details");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    handleClick : function(component, event, helper) {
        var source = event.getSource();
        var label = source.get('v.label');
        console.log('label = ' + label);
        if (label == 'Home') {
            var urlEvent = $A.get('e.force:navigateToURL');
        	urlEvent.setParams({ 'url' : '/' });
        	urlEvent.fire();
        }
        if (label == 'Logout') {
            var urlString = window.location.href;
 			var baseURL = urlString.substring(0, urlString.indexOf('/s/'));
            window.location.href = baseURL + '/secur/logout.jsp';
        }
    }
    
})