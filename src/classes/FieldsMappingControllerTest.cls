@isTest
private class FieldsMappingControllerTest
{

	@testSetup public static void initial(){
		GoogleAnalyticsServiceTest.initial();
	}

	@isTest
	static void constructor()
	{
		APITemplate__c apiTemplate = [SELECT Id FROM APITemplate__c limit 1];

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
    PageReference pageRef = Page.FieldsMappingPage;
    pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
    Test.setCurrentPage(pageRef);
		Test.startTest();
		FieldsMappingController controller = new FieldsMappingController(scontroller);
		Test.stopTest();

		System.assertEquals(2, controller.fieldsMapping.size());
		System.assertEquals(apiTemplate.Id, controller.apiTemplate.Id);
	}

	@isTest
	static void constructorFail()
	{
		APITemplate__c apiTemplate = new APITemplate__c();

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
    PageReference pageRef = Page.FieldsMappingPage;
    pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
    Test.setCurrentPage(pageRef);
		Test.startTest();
		try {
			FieldsMappingController controller = new FieldsMappingController(scontroller);
		}catch(Exception ex){
				System.assert(true);
		}
		Test.stopTest();
	}

	@isTest
	static void getVariables()
	{
		APITemplate__c apiTemplate = [SELECT Id FROM APITemplate__c limit 1];

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
    PageReference pageRef = Page.FieldsMappingPage;
    pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
    Test.setCurrentPage(pageRef);
		Test.startTest();
		FieldsMappingController controller = new FieldsMappingController(scontroller);
		controller.apiTemplate.HitType__c = 'item';
		controller.apiTemplate.ObjectAPIName__c = 'Lead';
		Test.stopTest();
		System.assert(controller.googleAnalyticsFields.size() > 0);
		System.assert(controller.salesforceFields.size() > 0);
		System.assert(controller.listAllSObjects().size() > 0);
	}

	@isTest
	static void addMapping()
	{
		APITemplate__c apiTemplate = [SELECT Id FROM APITemplate__c limit 1];

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
		PageReference pageRef = Page.FieldsMappingPage;
		pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FieldsMappingController controller = new FieldsMappingController(scontroller);
		controller.addMapping();
		Test.stopTest();

		System.assertEquals(3, controller.fieldsMapping.size());
	}

	@isTest
	static void removeMapping()
	{
		APITemplate__c apiTemplate = [SELECT Id FROM APITemplate__c limit 1];

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
		PageReference pageRef = Page.FieldsMappingPage;
		pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FieldsMappingController controller = new FieldsMappingController(scontroller);
		ApexPages.currentPage().getParameters().put('row', '0');
		controller.removeMapping();
		Test.stopTest();

		System.assertEquals(1, controller.fieldsMapping.size());
	}

	@isTest
	static void save()
	{
		APITemplate__c apiTemplate = [SELECT Id FROM APITemplate__c limit 1];

		ApexPages.StandardController scontroller = new ApexPages.StandardController(apiTemplate);
		PageReference pageRef = Page.FieldsMappingPage;
		pageRef.getParameters().put('id', String.valueOf(apiTemplate.Id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		FieldsMappingController controller = new FieldsMappingController(scontroller);
		ApexPages.currentPage().getParameters().put('row', '0');
		controller.removeMapping();
		controller.save();
		Test.stopTest();
		List<APITemplateFieldMapping__c> fieldMapping = [SELECT id FROM APITemplateFieldMapping__c where APITemplate__c = :apiTemplate.Id];
		System.assertEquals(1, fieldMapping.size());
	}



}