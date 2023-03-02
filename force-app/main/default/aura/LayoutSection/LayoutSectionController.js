({
    setRenderProperty : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var name = event.getParam("name");
            var isRendered = event.getParam("isRendered");
            if (component.get("v.name") == name) {
                component.set("v.isRendered", isRendered);
            }
        }
    },
    
    changeSectionState : function(component, event, helper) {
        event.preventDefault();
        component.set('v.isExpanded', !component.get('v.isExpanded'));
    }
})