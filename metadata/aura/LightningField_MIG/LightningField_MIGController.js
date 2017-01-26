({  
   

    doInit : function(component) {
        console.log("El Registro: ");
        var record = component.get("v.record");
        console.log("El Describe:");
        var fieldDescribe = component.get("v.fieldDescribe");
        console.log(record);
        var output;
        var parts = fieldDescribe.original.split(".");
        console.log(parts);
        console.log("Punto de control 1"); 
        console.log("Es bold? "+component.get("v.boldFields")+", "+fieldDescribe.describe.name+": "+component.get("v.boldFields").indexOf(fieldDescribe.describe.name));
        
        if (component.get("v.boldFields").indexOf(fieldDescribe.describe.name)>-1) {
        	console.log('Es bold!');
       	 	var cmpTarget = component.find('texto');
       	 	$A.util.addClass(cmpTarget, "negrita");
        }
        if(fieldDescribe.related && record!== undefined  ){
            output = record[parts[0]][parts[1]];
        } else {
	        output = record[fieldDescribe.describe.name];            
        }
       
        //NAvegando a registros relacionados!
        if (fieldDescribe.describe.name=="Name") {
            if(fieldDescribe.related ) {
                component.set("v.destino",record[parts[0]]['Id']);
            } else {
               component.set("v.destino",record['Id']);
           }
        }
        
        component.set("v.simpleOutput", output);
       if (output!== undefined && typeof output === 'string') {
      //  component.set("v.Image", output.indexOf("<img")!==0);
      
      var str = output;
      var n = str.includes("<img");
      component.set("v.Image", n);
	        console.log("Punto de control 2");
        }
         console.log("Prueba: "+component.get("v.Image"));
        console.log("Field: "+fieldDescribe.describe.name+" Link a: "+component.get("v.id"));
        
    },
    navToRecord : function(component, event){
    	console.log("nav invoked, get id first");

    	console.log(event.target);
    	console.log("EL ID ES:");
    	var recordId = event.target.id;
    	console.log(recordId);
    	console.log("Invocando acción...");
    	var navEvt = $A.get("e.force:navigateToSObject");
	    navEvt.setParams({
	      "recordId": recordId
	    });
	    navEvt.fire();
    },
    changePicklist: function(component, event){
    	console.log(event.target);
        //answer[answer.selectedIndex].value
        //
        //
        
        var record=component.get("v.record");
        var fieldDescribe=component.get("v.fieldDescribe");
        //NOTA MENTAL: Event target no funciona con el lockerservice (al menos en winter17)
        console.log("Cambio de Valor***");
        console.log("length:"+event.target.length);
        console.log("Indice:"+event.target.selectedIndex);
        console.log("ID: "+record.Id);
        console.log("Campo: "+ fieldDescribe);
        console.log("Valor: "+event.target[event.target.selectedIndex]);
        var newValue=event.target[event.target.selectedIndex].value
        console.log("Cambio de Valor***");
        console.log("Nuevo Valor: "+newValue);
        console.log("ID: "+record.Id);
        console.log("Campo: "+ fieldDescribe);
        
         if (fieldDescribe.related) {
            console.log("Es related. fk: "+fieldDescribe.describe.fk+", parentObject: " +fieldDescribe.parentObjectName );
            var action = component.get("c.updateRelatedField");
            action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : newValue,
            "fk" : fieldDescribe.describe.fk,
            "parentObject" : fieldDescribe.parentObjectName
        });
        } else {
        var action = component.get("c.updateField");
        action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : newValue
        });
    } 
        
        action.setCallback(this, function(a){
            var state = a.getState();
            if (state === "SUCCESS") {
                //update local picklist value?
                component.set("v.simpleOutput", newValue);
                 if (component.get("v.autoRefresh")) {
                    
                	var evt_refresh = $A.get("e.c:PowerRefresh_MIG");
                    evt_refresh.fire();
            	}	
            }  else if (state === "ERROR") {
                console.log(a);        	
            }            
        });
        $A.enqueueAction(action);
    },
    
    flipCheckbox: function(component){
        console.log("checkbox flipped");          
        //flip value locally
        
        //update Salesforce
        
        var record=component.get("v.record");
        var fieldDescribe=component.get("v.fieldDescribe");
        
        if (fieldDescribe.related) {
            console.log("Es related. fk: "+fieldDescribe.describe.fk+", parentObject: " +fieldDescribe.parentObjectName );
            var action = component.get("c.updateRelatedField");
            action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : !component.get("v.simpleOutput"),
            "fk" : fieldDescribe.describe.fk,
            "parentObject" : fieldDescribe.parentObjectName
        });
        } else {
        var action = component.get("c.updateField");
        action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : !component.get("v.simpleOutput")
        });
    } 

        
        action.setCallback(this, function(a){
            var state = a.getState();
            if (state === "SUCCESS") {                
                component.set("v.simpleOutput", !component.get("v.simpleOutput"));
                 if (component.get("v.autoRefresh")) {
                    
                	var evt_refresh = $A.get("e.c:PowerRefresh_MIG");
                    evt_refresh.fire();
            	}	
            }  else if (state === "ERROR") {
                console.log(a);        	
            }
        });
        $A.enqueueAction(action);
    },
    
    updateRecord: function(component, event){
        
        console.log(event.target.value);
        //    public static void updateField(id recordId, string Field, string newValue){
        var fieldDescribe=component.get("v.fieldDescribe");
        var record=component.get("v.record");

        console.log("recordId : " + record.Id);
        console.log("fieldName : " + fieldDescribe.describe.name);
        

        if (fieldDescribe.related) {
            console.log("Es related. fk: "+fieldDescribe.describe.fk+", parentObject: " +fieldDescribe.parentObjectName );
            var action = component.get("c.updateRelatedField");
            action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : event.target.value,
            "fk" : fieldDescribe.describe.fk,
            "parentObject" : fieldDescribe.parentObjectName
        });
        } else {
        var action = component.get("c.updateField");
        action.setParams({
            "recordId" : record.Id,
            "Field" : fieldDescribe.describe.name,
            "newValue" : event.target.value
        });
    } 
        
        action.setCallback(this, function(a){
            var state = a.getState();
            console.log("Actualizando Registro, state: "+state);
            if (state === "SUCCESS") {
                console.log(a);
                console.log("Pidiendo Refesco"+component.get("v.autoRefresh"));
                if (component.get("v.autoRefresh")) {
                	var evt_refresh = $A.get("e.c:PowerRefresh_MIG");
                    evt_refresh.fire();
            	}	
            }  else if (state === "ERROR") {
                console.log(a);        	
            }            
        });
        $A.enqueueAction(action);
    }
})