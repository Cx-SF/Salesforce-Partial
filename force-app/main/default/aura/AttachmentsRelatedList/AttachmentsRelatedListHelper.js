({
	initTableColumns : function(cmp) {		
		cmp.set('v.attachmentColumns', [
		    { label: 'Title', fieldName: 'title', type: 'text',sortable : true},
		    { label: 'Uploaded Date', fieldName: 'createdDate', type: 'date', sortable : true, editable: false , typeAttributes:{month:'2-digit',day:'2-digit',year:'numeric', hour:"2-digit", minute:'2-digit', second: '2-digit' }},
		    { label: 'Size', fieldName: 'textSize', type: 'text',sortable : true},
            { label: 'Type', fieldName: 'type', type: 'text',sortable : true},
		    { label: 'Created By', fieldName: 'createdByName', type: 'text',sortable : true},
		    {type: "button", typeAttributes: {
		                    label: "View",
		                    name: 'View',
		                    title: 'View',
		                    disabled: false,
		                    value: 'view',
		                    iconPosition: 'left'
		                },
		                fieldName: 'title',
		                cellAttributes : { class:"cellButtonLink" }
		    },
            {type: "button", typeAttributes: {
		                    label: "Download",
		                    name: 'Download',
		                    title: 'Download',
		                    disabled: false,
		                    value: 'Download',
		                }
		    }
		]);

	},

	loadAttachments : function(cmp) {
        let openedFromEmail = cmp.get("v.openedFromEmails");
        let acction =  openedFromEmail ? cmp.get("c.getAttachmentsForEmail") : cmp.get("c.getAttachments");
		acction.setParams({"parentId" : cmp.get("v.recordId")});
		acction.setCallback(this, function (response) {
			if (response.getState() === "SUCCESS") {
				let attachments = response.getReturnValue();
				
				console.log("data "+ JSON.stringify(attachments));
				console.log(attachments);
                if(attachments.length){
                     attachments.sort(function(a, b) {
                        var c = new Date(a.createdDate);
                        var d = new Date(b.createdDate);
                        return c-d;
                    });
                    attachments = attachments.reverse();
                    const thisHelper = this;
                    attachments.forEach(function(att){
                        att.textSize = thisHelper.humanFileSize(att.size,false);
                    });
                }
                cmp.set("v.attachments", attachments );
			} else {
				console.log("Init data error "+ JSON.stringify(response.getError()));
			}
		});
		$A.enqueueAction(acction);
	},

	preview : function(cmp) {
	},

	sort : function(cmp, evt) {
		//Returns the field which has to be sorted
		var sortBy = evt.getParam("fieldName");
		//returns the direction of sorting like asc or desc
		var sortDirection = evt.getParam("sortDirection");
		//Set the sortBy and SortDirection attributes
		cmp.set("v.sortBy",sortBy);
		cmp.set("v.sortDirection",sortDirection);
		// call sortData helper function
		// helper.sortData(cmp,sortBy,sortDirection);

		var data = cmp.get("v.attachments");
		//function to return the value stored in the field
		var key = function(a) { return a[sortBy]; }
		var reverse = sortDirection == 'asc' ? 1: -1;
		
		// to handel number/currency type fields 
		// if(sortBy == 'NumberOfEmployees'){ 

		// }
		// else{// to handel text type fields 
	    data.sort(function(a,b){ 
	        var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
	        var b = key(b) ? key(b).toLowerCase() : '';
	        return reverse * ((a>b) - (b>a));
	    });    
		// }
		cmp.set("v.attachments",data);
	},
    
    humanFileSize : function humanFileSize(bytes, si) {
        var thresh = si ? 1000 : 1024;
        if(Math.abs(bytes) < thresh) {
            return bytes + ' B';
        }
        var units = si
        ? ['kB','MB','GB','TB','PB','EB','ZB','YB']
        : ['kB','MB','GB','TB','PB','EB','ZB','YB'];
        var u = -1;
        do {
            bytes /= thresh;
            ++u;
        } while(Math.abs(bytes) >= thresh && u < units.length - 1);
        return bytes.toFixed(1)+' '+units[u];
    }
})