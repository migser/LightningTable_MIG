public class LTableMigCtrl {
    //Controlador de Powerrelated list
    // Nueva Versión
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
    public static string formatea(List<sObject> resultados, String describeFields) {
        Integer debug_mode=2;
        descRowLTMigParser descripcion = descRowLTMigParser.parse(describeFields);
        if (debug_mode>=1) {
            System.debug('**empezando Formatea!');
 	        System.debug('*** Campos :'+descripcion.queryFields);
        }

        Map<String,descRowLTMigParser.Fields> campos = descripcion.map_fields;
        Set<String> dispFields = new Set<String>(descripcion.queryFields.toLowerCase().split(','));
        List<Map<String,Object>> resultado = new List<Map<String,Object>>();
		if (debug_mode>=2) {            
	            System.debug('****Campos SON: '+dispFields);
            }
        
        for ( sObject s : resultados) {
            if (debug_mode>=2) {            
	            System.debug('****Formateando registro: '+s.id);
            }
            Map<String, Object> record = new Map<String, Object>();
            for (String c : dispFields){
                Map<String, Object> field = new Map<String, Object>();
                if (debug_mode>=2) {            
	         	   System.debug('******Formateando campo: '+c+': '+campos.get(c));
            	}
                if (campos.containsKey(c) && campos.get(c).valid) {
                    if (campos.get(c).related) {
                        
                        field.put('nav',true);
                        field.put('fk',s.get(campos.get(c).fk));
                        field.put('recordid',s.get(campos.get(c).fk));
                        
                    }
                    if (c.equalsIgnoreCase('name')) {
                        
                        field.put('nav',true);
                        field.put('fk',s.get('id'));
                    }
                    if (!campos.get(c).related){
                        field.put('recordid',s.get('id'));
                    }
                    field.put('value', getValor(s,c));
                    field.put('type', campos.get(c).type_Z);
                    field.put('label', campos.get(c).label);
                    field.put('name', campos.get(c).name);
                    field.put('id', campos.get(c).id);
                    record.put(c,field);
                }   
               
            }
            resultado.add(record);
        }
        
        
        return JSON.serialize(resultado);
    }
  
    public static Object getValor(sObject s, String c){
        if (c.contains('.')) {
            Integer separador=c.indexOf('.');
            String new_obj = c.substring(0,separador );
            String resto = c.substring(separador +1);
            System.debug('Recursivo: ('+new_obj+', '+resto+')' );
            return getValor(s.getSObject(new_obj),resto);
        } else {
            System.debug('Fin Recursividad: ('+c+')' );
	        return s.get(c);
        }
    }
    
    @AuraEnabled
    public static string query2(string selectFields,string lookupField,string sObjectName,string parentId,string recordId,String filter,string orderby,String describeFields) {
        
        Integer debug_mode=2;
        String select_str ='Select '+selectFields;
        String from_str =' From '+sObjectName;
        String where_str ='';
        String order_str = '';
		
        //ES RELATED?
        if (lookupField!=null&&!lookupField.equals('')) {
            where_str = ' Where '+lookupField+'=\'';
            //HAY QUE BUSCAR AL PADRE O SOY YO?
            if (parentId!=null&&!parentId.equals('')) {
                where_str = where_str+getParentId( sObjectName,  parentId,  recordId) + '\'';
            } else {
                where_str = where_str+recordId+'\''; 
            }
        }
        //TIENE FILTRO?
        if (filter!=null&&!filter.equals('')) {
            if (where_str=='') {
                where_str=' Where '+filter;
            } else {
            	where_str =where_str+ ' AND ' + filter;
            }
        }
		//Esta ordenada? 
          if (orderby!=null&&!orderby.equals('')) {
            order_str = ' Order by '+orderby;
         }
        if (debug_mode>=1){
            System.debug('**Ejecutando query --> '+select_str+from_str+where_str+order_str);
        }
        List<sObject> resultados = Database.query(select_str+from_str+where_str+order_str);
        
         if (debug_mode>=1){
            System.debug('**Resultado query --> '+JSON.serialize(resultados));
        } 
		return formatea(resultados, describeFields);
       

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
	public static Map<String, Object> describe_related(string parentObject, String field) {
        Map<String, Object> result = new Map<String, Object>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(parentObject);
        Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
        if (fieldMap.containsKey(field)){
        	Schema.DescribeFieldResult descField = fieldMap.get(field).getDescribe();
            result.put('type', descField.getType().name().toLowerCase());
            result.put('name', descField.getName());
            result.put('label', descField.getLabel());   
            result.put('valid',true);
            result.put('related',true);
            result.put('parentObject',parentObject);
        } else {
            result.put('related',true);
            result.put('parentObject',parentObject);
            result.put('valid',false);
            result.put('error','Invalid field name');
        }
                
    	return result;
    }
    @AuraEnabled
    public static String describe2(string displayFields, string sObjectName, string parentId, string recordId, String filter, string orderby) {
        Integer debug_mode=0;
        if (debug_mode>=2){
            System.debug('**Empezando describe2 **');
            System.debug('--Parametros:');
            System.debug('----displayFields: '+displayFields);
            System.debug('----parentId: '+parentId);
            System.debug('----recordId: '+recordId);
            System.debug('----filter: '+filter);
            System.debug('----orderby: '+orderby);
            
        }
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName);
        if (targetType == null) {
            return '[{"message":"The requested resource does not exist","errorCode":"NOT_FOUND"}]';
        }

        Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
        
        Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();
        
        List<Object> fields = new List<Object>();
        Set<String> dispFields = new Set<String>(displayFields.toLowerCase().split(','));
        if (debug_mode>=2){
            System.debug('--Sacando los metadatos de los campos:');
        }
        // NOTA: Por ahora no funciona con relaciones polimórficas...
       // Map<String,List<Schema.sObjectType>> obj_relations = new Map<String,List<Schema.sObjectType>>();
        Map<String,Map<String,String>> obj_relations = new Map<String,Map<String,String>>();
        for(Schema.SObjectField f : fieldMap.values()){
            Schema.DescribeFieldResult d = f.getDescribe();
            if (d.getRelationshipName()<>null && d.getReferenceTo().size()>0) {
                Map<String,String> rel = new Map<String,String>();
                rel.put('parentObject', d.getReferenceTo().get(0).getDescribe().getName());
                rel.put('fk', d.getName());
                obj_relations.put(d.getRelationshipName().toLowerCase(), rel);
        
                if (debug_mode>=2){
                    System.debug('--Relación de : '+d.getName());
                    System.debug('----Nombre : '+d.getRelationshipName());
                    for(Schema.SObjectType reference : d.getReferenceTo()) {
                        System.debug('------object name: ' + reference.getDescribe().getName());
                        System.debug('------object label: ' + reference.getDescribe().getLabel());
                    }
                } 
            }
        }
        String queryFields = 'id';

        
        for (String key : dispFields) {
            if (debug_mode>=2){
                System.debug('--Campo: '+key);
            }
            Map<String, Object> field = new Map<String, Object>();   
            field.put('id',key);
            //Solo hacemos el describe de los campos incluidos en display fields
            if (fieldMap.containsKey(key)){
			
            	Schema.DescribeFieldResult descField = fieldMap.get(key).getDescribe();
            	   
            	field.put('type', descField.getType().name().toLowerCase());
            	field.put('name', descField.getName());
            	field.put('label', descField.getLabel());   
                field.put('valid',true);
                if (!key.equalsIgnoreCase('id')) {
                	queryFields= queryFields+','+key;
                    if (debug_mode>=2){
                        System.debug('----Añadimos el campo: '+key+' a la lista de queryFields.');
                    }
                }
                
                if (debug_mode>=2){
           		 
                    System.debug('----Nombre: '+key);
                    System.debug('----Label: '+field.get('label'));
                    System.debug('----Nombre: '+field.get('name'));
                    System.debug('----Tipo: '+field.get('type'));
        		}
                
                //Si es Picklist sacamos los posibles valores
                if (field.get('type')=='picklist'){
                	List<Schema.PicklistEntry> pickListValues = descField.getPickListValues();
                	List<pickListValues> options = new List<picklistValues>();
                	for (Schema.PicklistEntry plv : pickListValues) {
                    	pickListValues pv = new pickListValues();
	                    pv.label = plv.getLabel();
    	                pv.value = plv.getValue();
        	            options.add(pv);
            	    }
                    if (debug_mode>=2){
           			    System.debug('----Valores Picklist: '+options);
                    }
                	field.put('picklistOptions', options);
            	}
                
                
            } else {
                if (key.contains('.')) {
                   Integer i = key.indexOf('.');
                   String relacion = key.substring(0, i);
                   String resto = key.substring(i+1);
                   
                   if (debug_mode>=2){
           			    System.debug('----Es una relación: ');
                       System.debug('------Relación: '+relacion);
                       System.debug('------Campo: '+resto);
                    }
                    if (obj_relations.containsKey(relacion)){
                            	
                                if (debug_mode>=2){
                                    System.debug('------referencia a : '+obj_relations.get(relacion));
                                }
                        Map<String, Object> result = describe_related(obj_relations.get(relacion).get('parentObject'),resto);
                        field.putAll(result);
                        field.put('fk',obj_relations.get(relacion).get('fk'));
                        if ((Boolean)result.get('valid')) {
                            //Solo añadimos la FK y el campo a la select si está todo Ok
	                        queryFields=queryFields+','+key;
                            if (!queryFields.contains(obj_relations.get(relacion).get('fk'))) {
    	                        queryFields=queryFields+','+obj_relations.get(relacion).get('fk');
        	                }
                            
                        }
                                     
                             
                    } else {
                        field.put('valid',false);
                            field.put('error','Invalid relationship');
                        if (debug_mode>=2){
           			    	System.debug('----La relación no existe!');
                            
                    	}
                    }
                    
                } else {
                    field.put('valid',false);
                         field.put('error','Invalid field name');
                  	if (debug_mode>=2){
           			    System.debug('----Este campo no existe!');
                        
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
        result.put('queryFields', queryFields);
        
        if (debug_mode>=1){
        	System.debug('***Resultado Final***');
            System.debug('--Plural: '+((map<string, string>)result.get('objectProperties')).get('pluralLabel'));
            System.debug('--Select: '+result.get('queryFields'));
			System.debug('--Campos: ');
            List <Object> fs = (List<Object>)result.get('fields');
                for (Object f2 : fs) {
                    Map<String, Object> f = (Map<String, Object>)f2;
                    System.debug('-*-*Campo: '+f.get('id') );                      
                    System.debug('----Label: '+f.get('label'));
                    System.debug('----Nombre: '+f.get('name'));
                    System.debug('----Tipo: '+f.get('type'));
                    System.debug('----Valores Picklist: '+f.get('picklistOptions'));
                    System.debug('----Relacion: '+f.get('related'));
                    System.debug('----Padre: '+f.get('parentObject')); 
                    System.debug('----Fk: '+f.get('fk')); 
                    System.debug('----Valido: '+f.get('valid'));
                    System.debug('----Error: '+f.get('error'));
               	}
         }
        
        return JSON.serialize(result);
            
      

    }
    
  
    
}