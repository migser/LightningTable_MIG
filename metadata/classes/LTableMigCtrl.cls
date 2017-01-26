public class LTableMigCtrl {
    //Controlador de Powerrelated list
    @AuraEnabled
    public static string query(String soql,string sObjectName, string parentId, string recordId, String filter, string orderby) {
        
        String query ='';
        String filtro ='';
        System.debug('Empezando con query: ');
        System.debug('soql: '+ soql);
        System.debug('sObjectName: '+ sObjectName);
		System.debug('parentId: '+ parentId);
        System.debug('RECORDID: '+ recordId);
        System.debug('Filtro: '+ filter);
        if (filter!=null&&!filter.equals('')) {
            filtro = ' AND ' + filter;
                }
        System.debug('filtro: '+filtro);
        if (parentId!=null&&!parentId.equals('')) {
            query = soql +getParentId( sObjectName,  parentId,  recordId) + '\''+ filtro;
        } else {
            query = soql +recordId + '\''+ filtro;
        }
         
         String order = 'Name';
          if (orderby!=null&&!orderby.equals('')) {
            order = orderby;
         }
         System.debug('Query: '+query+' Order by '+order);
        return JSON.serialize(Database.query(query+' Order by '+order));

       

    }
    
	@AuraEnabled
    public static string getParentId(string sObjectName, string parentId, string recordId) {
         string soql = 'select Id, ' + parentId +' from ' + sObjectName + ' where id = \'' + recordId + '\'';
        System.debug('Sacando info del PAdre:' + soql);
        
        try {
            list<sobject> records = Database.query(soql);
            System.debug('Sacando info del PAdre: OK' );
            return (String) records[0].get(parentId);
        }
        catch (Exception e) {
                system.debug('Excepción: '+e);
            	return null;
        }
    }    

    @remoteAction @AuraEnabled
    public static String describe(String objtype, String childobj, String relation) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objtype);
        if (targetType == null) {
            return '[{"message":"The requested resource does not exist","errorCode":"NOT_FOUND"}]';
        }

        
        Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
        
        Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
        
        List<Object> fields = new List<Object>();
      

        for (String key : fieldMap.keySet()) {
            Schema.DescribeFieldResult descField = fieldMap.get(key).getDescribe();
            Map<String, Object> field = new Map<String, Object>();
            
            field.put('type', descField.getType().name().toLowerCase());
            field.put('name', descField.getName());
            field.put('label', descField.getLabel());
            
            //if a field is a picklist, I want the values
            if (field.get('type')=='picklist'){
                List<Schema.PicklistEntry> pickListValues = descField.getPickListValues();
                List<pickListValues> options = new List<picklistValues>();
                for (Schema.PicklistEntry plv : pickListValues) {
                    pickListValues pv = new pickListValues();
                    pv.label = plv.getLabel();
                    pv.value = plv.getValue();
                    options.add(pv);
                }
                field.put('picklistOptions', options);
            }
            
            List<String> references = new List<String>();
            for (Schema.sObjectType t : descField.getReferenceTo()) {
                references.add(t.getDescribe().getName());
            }
            if (!references.isEmpty()) {
                field.put('referenceTo', references);
            }
            System.debug('Las referencias son:');
            System.debug(references);
            if (childobj!=null && relation!=null) {
                Schema.SObjectType targetType_child = Schema.getGlobalDescribe().get(childobj);
                Schema.DescribeSObjectResult sobjResult_child = targetType_child.getDescribe();
                Map<String, Schema.SObjectField> fieldMap_child = sobjResult_child.fields.getMap();
                for (String key_child : fieldMap_child.keySet()) {
                    Schema.DescribeFieldResult descField_child = fieldMap_child.get(key_child).getDescribe();
                    if (descField_child.getRelationshipName()==relation) {
                        System.debug('Enontrada FK '+key_child + ' '+descField_child.getRelationshipName());
                        field.put('fk',key_child);
                    }
                }
            }

            fields.add(field);
        }

  
        
        Map<String, Object> result = new Map<String, Object>();
        result.put('fields', fields);
        
        map<string, string> objectProperties = new map<string, string>();
        objectProperties.put('pluralLabel', sobjResult.getLabelPlural());
        result.put('objectProperties', objectProperties);
        System.debug('El Decribe es:'+result);
        return JSON.serialize(result);
    }

     @AuraEnabled
    public static void updateRelatedField(id recordId, string Field, string newValue, String fk, String parentObject){
        system.debug('Updateando un related');
        Schema.SObjectType sobjectType = recordId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        SObject obj = Database.query('Select Id, ' + fk + ' From ' + sobjectName + ' Where Id = \'' + recordId + '\'');
        updateField((Id)obj.get(fk), Field, newValue);
        
    }    
    @AuraEnabled
    public static void updateField(id recordId, string Field, string newValue){
        system.debug(' in the update function');
        Schema.SObjectType sobjectType = recordId.getSObjectType();
        String sobjectName = sobjectType.getDescribe().getName();
        
        SObject obj = Database.query('Select Id, ' + Field + ' From ' + sobjectName + ' Where Id = \'' + recordId + '\'');
        
        //what type of field are we?
        Schema.DisplayType valueType = getFieldType(sobjectName, Field);
        
        if (valueType != Schema.DisplayType.String) {
            // Coerce an incoming String to the correct type
            String svalue = (String)newValue;
            
            if (valueType == Schema.DisplayType.Date) {
                obj.put(Field, Date.valueOf(svalue));
            } else if ( valueType == Schema.DisplayType.DateTime) {
                obj.put(Field, DateTime.valueOf(svalue));
            } else if (valueType == Schema.DisplayType.Percent || valueType == Schema.DisplayType.Currency) {               
                obj.put(Field, svalue == '' ? null : Decimal.valueOf(svalue));
            } else if (valueType == Schema.DisplayType.Double) {
                obj.put(Field, svalue == '' ? null : Double.valueOf(svalue));
            } else if (valueType == Schema.DisplayType.Integer) {
                obj.put(Field, Integer.valueOf(svalue));
            } else if (valueType == Schema.DisplayType.Base64) {
                obj.put(Field, EncodingUtil.base64Decode(svalue.split(',')[1]));
            } else {
                obj.put(Field, svalue);
            }
        } else {
            // Just try putting the incoming value on the object
            obj.put(Field, newValue);
        }
        system.debug(obj);
        update obj;
    }
    
    //lovingly lifted from ngforce
    public static Schema.DisplayType getFieldType(string objectName, string fieldname){
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.sObjectField> targetFields = targetType.getDescribe().fields.getMap();
        return targetFields.get(fieldname).getDescribe().getType();
    }
    
    public class picklistValues {
		String label {get; set;}
		String value {get; set;}
	}
    
    //Controlador para las acciones
 /*   
    @AuraEnabled
    public static void borra(String ids, String objeto) {

        
        List<Id> values = (List<Id>)System.JSON.deserialize(ids,List<Id>.class);
        List<PreguntaPlantilla__c> a = [Select ID from PreguntaPlantilla__c where id =:values];
        delete a;         
        System.debug(values);
   
    }
        
    @AuraEnabled
    public static void clona(String ids, String objeto, Id recordId) {
        //SOLO RECIBE 1 ID
        
        List<Id> values = (List<Id>)System.JSON.deserialize(ids,List<Id>.class);
        List<PreguntaPlantilla__c> a = [Select Pregunta__C from PreguntaPlantilla__c where plantilla__c =:values];
        List<PreguntaPlantilla__c> viejos = [Select Id from PreguntaPlantilla__c where plantilla__c =:recordId];
        List<PreguntaPlantilla__c> nuevos = new List<PreguntaPlantilla__c>();
        for (PreguntaPlantilla__c pp : a ) {
            PreguntaPlantilla__c newpp = new PreguntaPlantilla__c (Plantilla__c = recordId, Pregunta__C = pp.Pregunta__C);
            nuevos.add(newpp);
        }    
        delete viejos;
        insert nuevos;   
        System.debug('clona :'+ values);
        System.debug('clona :'+ recordId);
        System.debug('clona :'+ objeto);
   
    }

    @AuraEnabled
    public static void copia(String ids, String objeto, Id recordId) {
        //SOLO RECIBE 1 ID
        
        List<Id> values = (List<Id>)System.JSON.deserialize(ids,List<Id>.class);
        List<PreguntaPlantilla__c> nuevos = new List<PreguntaPlantilla__c>();
        for (Id p : values ) {
            PreguntaPlantilla__c newpp = new PreguntaPlantilla__c (Plantilla__c = recordId, Pregunta__C = p);
            nuevos.add(newpp);
        }    
   
        insert nuevos;   
        System.debug('copia :'+ values);
        System.debug('copia :'+ recordId);
        System.debug('copia :'+ objeto);
   
    }*/
    
}