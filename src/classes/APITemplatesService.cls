public with sharing class APITemplatesService {

	public static Map<Id, APITemplate__c> getAPITemplateById(Set<Id> apiTemplateIds){
		Map<Id, APITemplate__c> apiTemplateById = new Map<Id, APITemplate__c>([
			SELECT
				Id, Name, HitType__c, ObjectAPIName__c,
				(
					SELECT
						Id, DefaultValue__c, ExternalFieldName__c, SalesforceFieldAPIName__c
					FROM
						APITemplateFieldMapping__r
		    )
			FROM
				APITemplate__c
			WHERE
				Id in :apiTemplateIds
		]);
		return apiTemplateById;
	}

	private static Set<String> getValidFieldNamesPerObject (Set<String> fieldNames , String sObjectName ){
		if (!Schema.getGlobalDescribe().containsKey(sObjectName)){
				throw new APITemplateException ('Invalid Object Name');
				return new Set<String>();
		}
		Set<String> validFieldNamesForObject = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().keySet();
		System.debug('Selected Fields '+ fieldNames);
		System.debug('All Fields '+ validFieldNamesForObject);
		validFieldNamesForObject.retainAll(fieldNames);
		System.debug('Retain Fields '+ validFieldNamesForObject);
		//Add Is Acessible
		return validFieldNamesForObject;
	}

	public static Map<Id, APITemplatesService.APITemplateResult> getAPITemplateResultById(Set<Id> apiTemplateIds){
		Map<Id, APITemplateResult> apiTemplateResultById = new Map<Id, APITemplateResult>();
		Map<String, APITemplateFieldMapping__c> apiTemplatefieldMappingByExternalValue  = new Map<String, APITemplateFieldMapping__c>();
		Map<Id, APITemplate__c> apiTemplateById = getAPITemplateById(apiTemplateIds);

		Set<String> m_salesforceFields = new Set<String>();
		for (APITemplate__c template : apiTemplateById.values()) {
			m_salesforceFields = new Set<String>();
			apiTemplatefieldMappingByExternalValue  = new Map<String, APITemplateFieldMapping__c>();
			System.debug(' Loop API Templates '+ template.Name);
			APITemplateResult  apiTemplateresult = new APITemplateResult(template);
			for (APITemplateFieldMapping__c fields : template.APITemplateFieldMapping__r) {
				if (fields.ExternalFieldName__c == null) {
					continue;
				}
				apiTemplatefieldMappingByExternalValue.put(fields.ExternalFieldName__c, fields);
				if (fields.SalesforceFieldAPIName__c != null) {
					//m_salesforceFields.add(String.valueOf(fields.SalesforceFieldAPIName__c).toLowerCase());
					String sfField = fields.SalesforceFieldAPIName__c;
          m_salesforceFields.add(sfField.toLowerCase());
				}
			}
			//Check if they are valid Fields
			m_salesforceFields = getValidFieldNamesPerObject (m_salesforceFields ,  template.ObjectAPIName__c );
			apiTemplateresult.addSalesforceFields(m_salesforceFields);
			apiTemplateresult.addSalesforceFieldMapping(apiTemplatefieldMappingByExternalValue);
			apiTemplateResultById.put(template.Id, apiTemplateresult);
		}
		return apiTemplateResultById;
	}

	public static String googleParametersJSON(){
		String json=		'{'+
		'  "hitTypes" :[ '+
		'	{' +
		'    "name" : "all",'+
		'    "fields" : ['+
		'      {"label": "Data Source", "key" : "ds", "required" : false},'+
		'      {"label": "IP Override", "key" : "uip", "required" : false},'+
		'      {"label": "Geographical Override", "key" : "geoid", "required" : false},'+
		'      {"label": "Tracking Id Override", "key" : "tid", "required" : false},'+
		'      {"label": "Queue Time", "key" : "qt", "required" : false},'+
		'      {"label": "User Id", "key" : "uid", "required" : false},'+
		'      {"label": "User Agent Override", "key" : "ua", "required" : false},'+
		'      {"label": "User Language", "key" : "ul", "required" : false},'+
		'      {"label": "Document Referrer", "key" : "dr", "required" : false},'+
		'      {"label": "Campaign Name", "key" : "cn", "required" : false},'+
		'      {"label": "Campaign Source", "key" : "cs", "required" : false},'+
		'      {"label": "Campaign Medium", "key" : "cm", "required" : false},'+
		'      {"label": "Campaign Keyword", "key" : "ck", "required" : false},'+
		'      {"label": "Campaign Content", "key" : "cc", "required" : false},'+
		'      {"label": "Campaign ID", "key" : "ci", "required" : false},'+
		'      {"label": "Google AdWords ID", "key" : "gclid", "required" : false},'+
		'      {"label": "Google Display Ads ID", "key" : "dclid", "required" : false},'+
		'      {"label": "Non-Interaction Hit", "key" : "ni", "required" : false},'+
		'      {"label": "Custom Parameter", "key" : "customParam", "required" : false}'+
		'    ]'+
		'  },'+
		'	{ '+
		'    "name" : "event", '+
		'    "fields" : ['+
		'      {"label": "Client Id" , "key" : "cid", "required" : true},'+
		'      {"label": "Event Category", "key" : "ec", "required" : true},'+
		'      {"label": "Event Action", "key" : "ea", "required" : true},'+
		'      {"label": "Event Label", "key" : "el", "required" : false},'+
		'      {"label": "Event Value", "key" : "ev", "required" : false}'+
		'    ]'+
		'  },'+
		'  {'+
		'    "name" : "transaction",'+
		'    "fields" : ['+
		'      {"label": "Client Id", "key" : "cid", "required" : true},'+
		'      {"label": "Transaction ID", "key" : "ti", "required" : true},'+
		'      {"label": "Transaction Affiliation", "key" : "ta", "required" : false},'+
		'      {"label": "Transaction Revenue", "key" : "tr", "required" : false},'+
		'      {"label": "Transaction Shipping", "key" : "ts", "required" : false},'+
		'      {"label": "Transaction Tax", "key" : "tt", "required" : false},'+
		'      {"label": "Currency Code", "key" : "cu", "required" : false}'+
		'    ]'+
		'  },'+
		'  {'+
		'    "name" : "item",'+
		'    "fields" : [ '+
		'      {"label": "Client Id", "key" : "cid", "required" : true},'+
		'      {"label": "Transaction ID", "key" : "ti", "required" : true},'+
		'      {"label": "Item Name", "key" : "in", "required" : true},'+
		'      {"label": "Item Price", "key" : "ip", "required" : false},'+
		'      {"label": "Item Quantity", "key" : "iq", "required" : false},'+
		'      {"label": "Item Code", "key" : "ic", "required" : false},'+
		'      {"label": "Item Category", "key" : "iv", "required" : false},'+
		'      {"label": "Currency Code", "key" : "cu", "required" : false}'+
		'    ]'+
		'  }'+
		'  ]'+
		'}';
		return json;
	}

	public class APITemplateResult {
		public APITemplate__c m_apiTemplateObj {get;set;}
		public Set<String> validSalesforceFieldNames {get;set;}
		public Map<String, APITemplateFieldMapping__c> apiTemplatefieldMappingByExternalValue {get;set;}
		public String query {get;set;}
		public APITemplateResult (APITemplate__c apiTemplateObj){
			m_apiTemplateObj = apiTemplateObj;
			validSalesforceFieldNames = new Set<String>();
			apiTemplatefieldMappingByExternalValue = new Map<String, APITemplateFieldMapping__c> ();
			System.debug('Initialized APITemplate Resutl ' + JSON.serialize(m_apiTemplateObj));
		}
		public void addSalesforceFields(Set<String> p_validSalesforceFieldNames ){
			System.debug('Object1: '+ m_apiTemplateObj );
      validSalesforceFieldNames = new Set<String>();
			validSalesforceFieldNames = p_validSalesforceFieldNames.clone();
			buildQuery();
		}
		public void addSalesforceFieldMapping(Map<String, APITemplateFieldMapping__c> apiTemplatefieldMapping){
			apiTemplatefieldMappingByExternalValue = new Map<String, APITemplateFieldMapping__c> ();
			apiTemplatefieldMappingByExternalValue.putAll(apiTemplatefieldMapping);
		}
		private void buildQuery(){
			if (!validSalesforceFieldNames.contains('id')){
				validSalesforceFieldNames.add('id');
			}
			System.debug('Fields: '+ validSalesforceFieldNames.size() + ' | '+ validSalesforceFieldNames  );
			System.debug('Object2: '+ m_apiTemplateObj );

			query = 'SELECT ' + String.join(new List<String>(validSalesforceFieldNames), ',') + ' FROM ' + m_apiTemplateObj.ObjectAPIName__c +
				' WHERE Id in :recordIds ' ;
		}
		public SObject[] retrieveRecords(Set<Id> recordIds) {
			return Database.query(query);
		}
	}

	public class APITemplateException extends Exception {

	}
}
