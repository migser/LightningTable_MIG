({
    //shared by lots of functions.  You give it a comma-separated list of stuff, it returns a trimmed array
    CSL2Array: function (CSL){
        
        try{
            var outputArray = CSL.split(",");
            _.forEach(outputArray, function (value, key){
                outputArray[key] = _.trim(value);
            });
            return outputArray;
        } catch(err){
            //intended to handel the "CSL is null scenario"
            return null;
        }
    },
    getParent: function (component, parentId, sObjectName, recordId, filter){
        var action = component.get("c.getParentId");
        action.setParams({"sObjectName" : sObjectName, "parentId" : parentId, "recordId" : recordId});
        action.setCallback(self, function(a){
            console.log("Get Parent ID!");	
            var p = a.getReturnValue()
            console.log(p);
            component.set("v.parentId_val", p);
            
            if (filter) {
        		var filtro = " and "+filter    
            } else {
            var filtro = ""    
            }
        
        
		var soql = "select Id, " + component.get("v.displayFields") + " from " + component.get("v.objectName") + " where " + component.get("v.lookupField") + " = '" + component.get("v.parentId_val") + "'" + filtro;		
		console.log("getParent invocando a query!");
        console.log(soql);
		//get the describe
		//this.query(component, soql); 
        });
        $A.enqueueAction(action);        
    },
    query: function (component, soql, parentId, sObjectName, recordId, filter, orderby){
        var action = component.get("c.query");
        console.log("helper.Query invocando a query!");
        var params = {"soql" : soql, 
                          "sObjectName" : sObjectName,
                          "parentId" : parentId,                          
                          "recordId" : recordId,
                          "filter" : filter,
                          "orderby" : orderby}
        action.setParams(params);
        action.setCallback(self, function(a){
            console.log("query results");	
            var records = JSON.parse(a.getReturnValue());
            console.log(records);
            component.set("v.results", records);
            component.set("v.showSpinner2", false);
        });
        console.log("Ejecutando query...");
        $A.enqueueAction(action);        
    },
    
    describe: function (component, objectName){
        
        var fieldsArray = this.CSL2Array(component.get("v.displayFields"));
        var editableFields = this.CSL2Array(component.get("v.editableFields"));
        
        //	public static String describe(String objtype) {
        var action = component.get("c.describe");
        action.setParams({"objtype" : objectName , "childobj": null, "relation": null}); 
        action.setStorable();
        action.setCallback(this, function (a){
            var displayFieldsArray=[];

            console.log("result in callback:");
            var output = JSON.parse(a.getReturnValue());
            component.set("v.pluralLabel", output.objectProperties.pluralLabel);
            console.log(output.fields);
            //now, only get the ones that are in the displayfieldsList  

            console.log("Valores "+output.fields);
            
            _.forEach(fieldsArray, function(value){
                //check for reference dot
                if (!value.includes(".")){ 
                    //just a normal, non-reference field
                    var temp = {
                        "describe" : _.find(output.fields, {"name" : value}), 
                        "original": value,
                        "editable" : _.includes(editableFields, value),
                        "related" : false,
                        "parentObjectName" : ''
                    };                    
                    displayFieldsArray.push(temp);                    
                } else { //it's a relationship/reference field                    
                    displayFieldsArray.push({
                        "describe": value, //placeholder, will update late with related object describe
                        "editable":_.includes(editableFields, value), 
                        "original":value,
                        "related":true,
                        "parentObjectName" : ''
                    });
                }
            });
           	
            //first (and possibly only) setting. Will update if parent fields found
            component.set("v.displayFieldsArray", displayFieldsArray);            
            console.log("done with normal fields");
            
            //related objects (up one level only!)
            _.forEach(fieldsArray, function(value){                
                if (value.includes(".")){
                    console.log("dependentField:" + value);
                    var parentDesribe = component.get("c.describe");
                    parentDesribe.setStorable();
                    //var parentObjectName = value.split(".")[0].replace("__r", "__c"); //replaces if custom
                    var parentObjectName = ''+(_.find(output.fields, {"name" : value.split(".")[0].replace("__r", "__c")})).referenceTo; //replaces if custom
                    var relationName = value.split(".")[0];
                    //do a describe for that object
                    //
                    parentDesribe.setParams({"objtype" : parentObjectName, "childobj": objectName, "relation": relationName});
                    var temp = {};
                    parentDesribe.setCallback(this, function (response){
                        displayFieldsArray = component.get("v.displayFieldsArray");
						console.log(response)                        
                        var relatedOutput = JSON.parse(response.getReturnValue());
                        console.log(relatedOutput);
                        //get the describe for that field
                        console.log("searched name is: " + value.split(".")[1])
                        temp = {"describe" : _.find(relatedOutput.fields, {"name" : value.split(".")[1]}),
                                "parentObjectName" : parentObjectName }
                        console.log(temp);
						//now temp is the describe.  Let's find where to put it
						var displayFieldIndex = _.findIndex(displayFieldsArray, { 'describe': value});
                        console.log("found index: " + displayFieldIndex);
						displayFieldsArray[displayFieldIndex].describe = temp.describe;
                        console.log(displayFieldsArray);
                    	component.set("v.displayFieldsArray", displayFieldsArray);
                    });
                    
                    $A.enqueueAction(parentDesribe);
                }
            });   
                    component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
        
    }
})