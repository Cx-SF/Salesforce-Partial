({
	init : function(component, event, helper) {
		helper.initTableColumns (component);
		helper.loadAttachments (component);
	},

	handleRowAction: function (component, event, helper) {
	        var action = event.getParam('action');
	        var row = event.getParam('row');
	        switch (action.name) {
	            case 'View':
	                var rowID = row.id;
                    if(rowID.startsWith("00P")){
                        component.set("v.isAttachment" , true);
                    } else {
                        component.set("v.isAttachment" , false);
                    }
	                // Do whatever you want with rowID
	                component.set("v.hasModalOpen" , true);
	                component.set("v.selectedDocumentId", rowID); 
					component.set("v.downloadUrl", row.downloadUrl); 
	                break;
                case 'Download' :
                    window.open(row.downloadUrl, '_blank');
                    break;
	       }
	},

	handleSort : function(component, event, helper) {
		helper.sort(component,event);
	},
	handleReload : function (component, event, helper) {
		helper.loadAttachments (component);
	},
	handleUploadFinished : function(component, event, helper) {
		helper.loadAttachments (component);
	},

	closeModel: function(component, event, helper) {
	    // for Close Model, set the "hasModalOpen" attribute to "FALSE"  
	    component.set("v.hasModalOpen", false);
	    component.set("v.selectedDocumentId" , null); 
	}
	
})