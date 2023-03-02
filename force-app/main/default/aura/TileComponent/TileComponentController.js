({
	doInit : function(cmp, event, helper) {
        helper.initTile(cmp,'ListView1');
        helper.initTile(cmp,'ListView2');
        helper.initTile(cmp,'ListView3');
        helper.initTile(cmp,'ListView4');
        helper.initCount(cmp);
    },
    navigateToList: function (cmp, event, helper) {
    	var idx = event.target.id;
    	var name = event.target.name;
    	var navEvent = $A.get("e.force:navigateToList");
    	navEvent.setParams({
    	    "listViewId": idx,
    	    "listViewName": null,
    	    "scope": name
    	});
    	navEvent.fire();
    }
})