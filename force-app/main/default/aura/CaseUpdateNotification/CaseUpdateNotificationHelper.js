({
    initSubscription: function (cmp) {
        var self = this;
        var empApi = cmp.find('empApi');
        empApi.isEmpEnabled().then(function(enabled) {
            if (!enabled) {
                console.error('Component must be hosted in the Salesforce One app in order to listen to platform events');
                return;
            }
            console.log('EMP API is enabled');
            //empApi.setDebugFlag(true);
            var onErrorCallback = function(error) {
                console.error('EMP API message: ' + JSON.stringify(error));
            }.bind(this);
            empApi.onError($A.getCallback(onErrorCallback));
            self.subscribeCommentNotification(cmp);
        });
        /*
        var errorHandler = function (message) {
            console.error('CaseUpdateNotification subscription: Received error: ', JSON.stringify(message));
        };
        empApi.onError($A.getCallback(errorHandler));
        this.subscribeCommentNotification(cmp);
        */
    },

    subscribeCommentNotification: function (cmp) {
        var self = this;
        var empApi = cmp.find("empApi");
        var channel = cmp.get("v.channel");
        var replayId = -1;
        var callback = function (message) {
            console.log("Event Received : " + JSON.stringify(message));
            var currentCase = cmp.get("v.currentCase");
            if (typeof(currentCase) == "undefined") return;
            var currentUserId = $A.get("$SObjectType.CurrentUser.Id");
            var currentCaseId = cmp.get("v.recordId");
            if(!cmp.get("v.isInUpdateProcess") && message.data.payload.CaseId__c === currentCase.Id
                && message.data.payload.CreatedById !== currentUserId)
            {
                self.onReceiveNotification(cmp, message, currentCase);
            }
        };
        //empApi.subscribe(channel, replayId, $A.getCallback(callback));
        empApi.subscribe(channel, replayId, $A.getCallback(callback))
        .then(subscription => {
            console.log('Subscribed to channel ', subscription.channel);
        });
        
    },

    onReceiveNotification: function (cmp, message, currentCase) {
        var Event_Type = message.data.payload.Event_Type__c;
        var MessageToUser;
        if ( Event_Type === "Case") {
            MessageToUser = "Case "+currentCase.CaseNumber+" was updated by ";
        } else if (Event_Type === "Comment") {
            MessageToUser = "Comment was added to the case "+currentCase.CaseNumber+" by ";
        } else if (Event_Type === "Email") {
            MessageToUser = "Email was added to the case "+currentCase.CaseNumber+" by ";
        }

        this.displayToast(cmp, MessageToUser + message.data.payload.Modified_By_User__c + " on " +message.data.payload.Local_DateTime__c);
    },

    displayToast: function (cmp, message) {
        var toastEvent = $A.get("e.force:showToast");
        var currentCaseId = cmp.get("v.recordId");
        console.log("Show event " + message);
        toastEvent.setParams({
            title: "Case Update Notification",
            mode: "sticky",
            // type: "info",
            type: "success",
            key: 'info_alt',
            message: message
        });
        toastEvent.fire();
    }
})