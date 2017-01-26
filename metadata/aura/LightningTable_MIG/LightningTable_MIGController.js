({
	doInit : function(component, event, helper) {
		//TODO: do a cleanup on displayFields parameter to make sure it's not invalid (commas, spaces, etc)
		
		//build the query
        //MODIFICACION MIGUEL: PARENT ID distinto a record ID
		
     /*   if (component.get("v.parentId")) {
            helper.getParent(component,component.get("v.parentId"), component.get("v.sObjectName"),component.get("v.recordId") )
           
        } else {
            component.set("v.parentId_val", component.get("v.recordId"))
        
        
        // MODIFICACION MIGUEL: Filtro Custom!
		
        if (component.get("v.filter")) {
        	var filtro = " and "+component.get("v.filter")    
            } else {
            var filtro = ""    
            }
        
        
		var soql = "select Id, " + component.get("v.displayFields") + " from " + component.get("v.objectName") + " where " + component.get("v.lookupField") + " = '" + component.get("v.parentId_val") + "'" + filtro;		
		*/
        
        var b = helper.CSL2Array(component.get("v.bold"));
        component.set("v.boldFields",b);
        console.log("BOLD: "+component.get("v.boldFields").indexOf('Amount'));
        
        component.set("v.showSpinner", true);
        if (component.get("v.acciones")) {
            component.find("all").set("v.value",false);
        }
        var s = [];
        component.set("v.selectedRecords",s);
        component.set("v.results",s);
        var soql = "select Id, " + component.get("v.displayFields") + " from " + component.get("v.objectName") + " where " + component.get("v.lookupField") + " = '";		
        console.log(soql);
		//get the describe
		helper.query(component, soql,component.get("v.parentId"), component.get("v.sObjectName"),component.get("v.recordId"),component.get("v.filter"), component.get("v.orderby")); 
       // }
		helper.describe(component, component.get("v.objectName")); 


	},
    

	navToRecord : function(component, event){
    	console.log("nav invoked, get id first");

    	console.log(event.target);
    	console.log("EL ID ES:");
    	var recordId = event.target.id;
    	console.log(recordId);
        console.log("Y el name es: "+event.target.nombre);
    	console.log("Invocando acción...");
    	var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	      "recordId": recordId
	    });
	    navEvt.fire();
    },

    createRecord : function (component) {
	    var createRecordEvent = $A.get("e.force:createRecord");
	    createRecordEvent.setParams({
	        "entityApiName": component.get("v.objectName")
	    });
	    createRecordEvent.fire();
	},
    selectRecord : function(component, event, helper) {
        var s = component.get("v.selectedRecords");     
        var index = event.getSource().get("v.name");
        var marcado = event.getSource().get("v.value");
        
        if (index=='all') {
            var total = component.get("v.results").length;
            var checks = component.find('Check');
            s = [];
            if (marcado) {
                if (Array.isArray(checks) ) {
                    for (i = 0; i < total; i++) {
                        var c = checks[i];
                        console.log("Encontrado componente? "+c);
                    	c.set("v.value",true);
                        s.push(component.get("v.results")[i].Id);
				    }
                } else {
                    console.log("Marcamos ALL para 1");
                    checks.set("v.value",true);
                    s.push(component.get("v.results")[0].Id);
                }
                
            } else {
                if (Array.isArray(checks) ) {
                    for (i = 0; i < total; i++) {
        				var c = checks[i];
                        c.set("v.value",false);
    				} 
                } else {
                        checks.set("v.value",false);
                    }
                
            }
            
        } else {
            component.find('all').set("v.value",false);
            console.log("Index: "+index);
            console.log(event.getSource().getLocalId());
            console.log(event.getSource().getGlobalId());
            console.log(component.find(event.getSource().getLocalId()));
            console.log(component.find(event.getSource().getGlobalId())); 
            console.log(component.find('CHK-'+index));
            if (marcado) {
                s.push(component.get("v.results")[index].Id);
                
            } else {
                var i = s.indexOf(component.get("v.results")[index].Id)
                if (1 > -1) {
                    s.splice(i, 1);
                }
            }
        }
            console.log(s);
        component.set("v.selectedRecords",s);
        component.set("v.selectedRecordsP",JSON.stringify(s));
    }
})