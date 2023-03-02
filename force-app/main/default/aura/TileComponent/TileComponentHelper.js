({
    initTile: function (cmp, name) {
        let str = cmp.get("v." + name);
        if (str != null) {
            let lwSplited = str.split("=#=");
            let lwId = lwSplited[0];
            let lwObjectName = lwSplited[1];
            let lwName = lwSplited[2];
            let lwObject = lwSplited[3];
            cmp.set("v." + name + "Id", lwId);
            cmp.set("v." + name + "ObjectName", lwObjectName);    
            cmp.set("v." + name + "Name", lwName);    
            cmp.set("v." + name + "Object", lwObject);    
            cmp.set("v." + name + "Count", 0);    
        }
    },
    initCount : function (cmp) {
        let id1 = cmp.get("v.ListView1Id");
        let obj1 = cmp.get("v.ListView1Object");
        let id2 = cmp.get("v.ListView2Id");
        let obj2 = cmp.get("v.ListView2Object");
        let id3 = cmp.get("v.ListView3Id");
        let obj3 = cmp.get("v.ListView3Object");    
        let id4 = cmp.get("v.ListView4Id");
        let obj4 = cmp.get("v.ListView4Object");
        let getCountMap = cmp.get("c.getListViewSizes");
        let paramList = [
            {"id":id1 , 
             "objType":obj1 
            },
            {"id":id2 , 
             "objType":obj2 
            },
            {"id":id3 , 
             "objType":obj3 
            },
            {"id":id4 , 
             "objType":obj4 
            }
        ];
        // let params = Object.assign({}, paramList);
        getCountMap.setParams({'lstviews': paramList});
        getCountMap.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let mapCount = response.getReturnValue();
                cmp.set("v.ListView1Count", mapCount[id1]);  
                cmp.set("v.ListView2Count", mapCount[id2]);  
                cmp.set("v.ListView3Count", mapCount[id3]);  
                cmp.set("v.ListView4Count", mapCount[id4]);  
            }
        });
        $A.enqueueAction(getCountMap);
    }
})