({
	parseURL : function() {
		var regex = /[?&]([^=#]+)=([^&#]*)/g,
	    url = window.location.href,
	    params = {},
	    match;
		while(match = regex.exec(url)) {
		    params[match[1].replace('c__', '')] = match[2];
		}
		return params;
	},
	getAll: function(cmp, evt){
		var action = cmp.get("c.getAll");
        action.setParams({ "articleId" : cmp.get('v.recordId') });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				console.log('storeResponse: ' + JSON.stringify(storeResponse));
				cmp.set('v.showSubscribe', storeResponse.subscribe);
				cmp.set('v.showUnSubscribe', storeResponse.unSubscribe);
				cmp.set('v.showSpecialSubscribe', storeResponse.specialSubscribe);
				cmp.set('v.communityBaseURL', storeResponse.communityBaseURL);
				cmp.set('v.article', storeResponse.article);
            } else {
				let err = response.getError();
				if (err && Array.isArray(err)){
					console.log('Error: ' + err[0].message);
				}
			}
        });
        $A.enqueueAction(action);
	},
	sub: function(cmp, evt){
		var action = cmp.get("c.subscribe");
        action.setParams({ "articleId" : cmp.get('v.recordId') });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				if (storeResponse == 'success'){
					cmp.set('v.showSubscribe', false);
					cmp.set('v.showUnSubscribe', true);
				}
            } else {
				let err = response.getError();
				if (err && Array.isArray(err)){
					console.log('Error: ' + err[0].message);
				}
			}
			cmp.set('v.disable', false);
        });
		cmp.set('v.disable', true);
        $A.enqueueAction(action);
	},
	unsub: function(cmp, evt){
		var action = cmp.get("c.unSubscribe");
        action.setParams({ "articleId" : cmp.get('v.recordId') });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				if (storeResponse == 'success'){
					cmp.set('v.showSubscribe', true);
					cmp.set('v.showUnSubscribe', false);
				}
            } else {
				let err = response.getError();
				if (err && Array.isArray(err)){
					console.log('Error: ' + err[0].message);
				}
			}
			cmp.set('v.disable', false);
        });
		cmp.set('v.disable', true);
        $A.enqueueAction(action);
	},
	getFieldById : function(cmp, fId){
		var fld = cmp.find(fId);
		if (!this.isEmpty(fld) && !this.isEmpty(fld.length)) fld = fld[0];
		return fld;
	},
	isEmpty : function(obj){
		return (obj == null || typeof(obj) == 'undefined' || obj == '' || obj == 'undefined');
	}
})