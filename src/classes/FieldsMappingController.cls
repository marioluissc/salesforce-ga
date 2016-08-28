public with sharing class FieldsMappingController {

		@testVisible
		private final APITemplate__c apiTemplate;
		public List<APITemplateFieldMapping__c> fieldsMapping { get; set;	}
		private List<APITemplateFieldMapping__c> fieldsMappingToDelete { get; set;	}

    public FieldsMappingController(ApexPages.StandardController stdController) {
			try {
				this.apiTemplate = (APITemplate__c) stdController.getRecord();
				if (this.apiTemplate.Id == null)
					throw new FieldMappingException('Please Inform the Template Id');
				initialize();
			} catch (Exception ex) {
				ApexPages.addMessages(ex);
			}
    }

		private void initialize() {
			fieldsMappingToDelete = new List<APITemplateFieldMapping__c>();
			fieldsMapping = new List<APITemplateFieldMapping__c>();
			fieldsMapping = [SELECT Id, Name, APITemplate__c , ExternalFieldName__c, SalesforceFieldAPIName__c, DefaultValue__c FROM APITemplateFieldMapping__c WHERE APITemplate__c = :apiTemplate.Id];
		}

		//PUBLIC

		public List<SelectOption> googleAnalyticsFields {
			get {
				if (apiTemplate.HitType__c != null){
					googleAnalyticsFields = listGoogleAnalyticsFields(apiTemplate.HitType__c);
				}
				return googleAnalyticsFields;
			}
			set;
		}

		public List<SelectOption> salesforceFields {
			get {
				if (apiTemplate.ObjectAPIName__c != null){
					salesforceFields = listSObjectFields(apiTemplate.ObjectAPIName__c);
				}
				return salesforceFields;
			}
			set;
		}

		public void addMapping(){
			fieldsMapping.add( new APITemplateFieldMapping__c(APITemplate__c = apiTemplate.Id ));
		}

		public void removeMapping(){
			Integer row = Integer.valueOf(ApexPages.currentPage().getParameters().get('row'));
			APITemplateFieldMapping__c fieldMappingDeleted = fieldsMapping.remove(row);
			if (fieldMappingDeleted.Id != null)
				fieldsMappingToDelete.add(fieldMappingDeleted);
		}

		public PageReference save(){
			try {
				if (!fieldsMappingToDelete.isEmpty()){
					Database.delete(fieldsMappingToDelete);
				}
				if (!fieldsMapping.isEmpty()){
					validateFieldMapping();
					Database.upsert(fieldsMapping);
				}
				PageReference pageRef = new PageReference('/'+apiTemplate.Id);
				return pageRef;
			}catch(Exception ex){
				ApexPages.addMessages(ex);
			}
			return null;
		}


		//PRIVATE

		private void validateFieldMapping() {
			for (APITemplateFieldMapping__c field : fieldsMapping ){
				if (field.ExternalFieldName__c == null)
					throw new FieldMappingException('Google Parameter Fields are required.');
				if (field.SalesforceFieldAPIName__c == null)
					throw new FieldMappingException('Salesforce fields are required. Select the option "Set a Default Value" to define a fixed value.');

			}

		}
		private List<SelectOption> listGoogleAnalyticsFields(String hitType){
			List<SelectOption> options = new List<SelectOption>();
			Map<String, List<GoogleAnalyticsParameter.Fields>> fieldsByEventName = getGoogleAnalyticsByHitTypeId();
			//List<Schema.SObjectType> allObjects = Schema.getGlobalDescribe().values();
			options.add( new SelectOption ('' , '-- Select a Parameter --' ));
			for (GoogleAnalyticsParameter.Fields field : fieldsByEventName.get(hitType) ) {
				options.add( new SelectOption (field.key , field.label + ' ('+ field.key +')' ));
			}
			options.add( new SelectOption ('' , '-- General Parameters --', true));
			for (GoogleAnalyticsParameter.Fields field : fieldsByEventName.get('all') ) {
				options.add( new SelectOption (field.key , field.label + ' ('+ field.key +')' ));
			}
			return options;
		}

		@testVisible
		private List<SelectOption> listAllSObjects(){
			List<SelectOption> options = new List<SelectOption>();
			//List<Schema.SObjectType> allObjects = Schema.getGlobalDescribe().values();
			options.add( new SelectOption ('' , '-- Select a Object --' ));
			for(Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values())
			{
				Schema.DescribeSObjectResult dObjectType = sObjectType.getDescribe();
				options.add( new SelectOption ( dObjectType.getName() , dObjectType.getLabel() + ' (' + dObjectType.getName() + ')' ));
			}
			return options;
		}

		private List<SelectOption> listSObjectFields(String objectApiName) {
			List<SelectOption> options = new List<SelectOption>();
			Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
			options.add( new SelectOption ('' , '-- Select a Field --' ));
			options.add( new SelectOption ('not_defined' , 'Set a Default Value' ));
			for(Schema.SObjectField sfield : fieldMap.Values())
			{
				Schema.DescribeFieldResult dfield = sfield.getDescribe();
				options.add( new SelectOption ( dfield.getName() , dfield.getLabel() + ' (' + dfield.getName() + ')' ));
			}
			return options;
		}

		private Map<String, List<GoogleAnalyticsParameter.Fields>> getGoogleAnalyticsByHitTypeId() {
			GoogleAnalyticsParameter parameters = GoogleAnalyticsParameter.parse(APITemplatesService.googleParametersJSON());
			return parameters.fieldsByEventName();
		}

		public class FieldMappingException extends Exception {

		}


}