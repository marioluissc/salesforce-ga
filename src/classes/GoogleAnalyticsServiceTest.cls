@isTest
public class GoogleAnalyticsServiceTest
{
	@testSetup public static void initial(){

		GoogleAnalyticsIntegration__c settings = customSettings();
		insert settings;

		APITemplate__c template = generateTemplate();
		insert template;
		List<APITemplateFieldMapping__c> fieldMapping = generateAPITemplate(template.Id);
		insert fieldMapping;

		GoogleAnalyticsApp__c app = generateApp();
		insert app;

		GoogleAnalyticsHitSettings__c hitSettings = generateHitSettings(app.Id);
		insert hitSettings;
		GoogleAnalyticsHitStep__c hitSettingsSteps = generateHitSteps(template.Id, hitSettings.Id);
		insert hitSettingsSteps;

	}

	@isTest
	static void hitRequest()
	{

		Lead leadR = generateLead();
		insert leadR;

		GoogleAnalyticsHitQueue__c hitQueue = new GoogleAnalyticsHitQueue__c(
			GoogleAnalyticsHitSettingsName__c = 'leadHitSettings',
			RecordId__c = leadR.Id
		);
		Test.setMock(HttpCalloutMock.class, new GAHttpCalloutMock());
		insert hitQueue;

		GoogleAnalyticsService.HitRequest hitRequest = new GoogleAnalyticsService.HitRequest(
			hitQueue.Id, 'leadHitSettings', new Set<Id> { hitQueue.RecordId__c}
		);
	}

	@isTest
	static void sendHitRequest()
	{
		Lead leadR = generateLead();
		insert leadR;

		GoogleAnalyticsHitQueue__c hitQueue = new GoogleAnalyticsHitQueue__c(
			GoogleAnalyticsHitSettingsName__c = 'leadHitSettings',
			RecordId__c = leadR.Id
		);
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new GAHttpCalloutMock());
		insert hitQueue;
		Test.stopTest();
	}

	@isTest
	static void sendHitRequestBatch()
	{
		Lead leadR = generateLead();
		insert leadR;
		Lead leadR2 = generateLead();
		leadR2.FirstName = 'Google app2';
		insert leadR2;

		GoogleAnalyticsHitQueue__c hitQueue = new GoogleAnalyticsHitQueue__c(
			GoogleAnalyticsHitSettingsName__c = 'leadHitSettings',
			RecordId__c = leadR.Id
		);

		GoogleAnalyticsHitQueue__c hitQueue2 = new GoogleAnalyticsHitQueue__c(
			GoogleAnalyticsHitSettingsName__c = 'leadHitSettings',
			RecordId__c = leadR2.Id
		);
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new GAHttpCalloutMock());
		insert (new List<GoogleAnalyticsHitQueue__c>{hitQueue, hitqueue2});
		GoogleAnalyticsHitQueue__c[] results = [SELECT Id, RunInBatch__c FROM GoogleAnalyticsHitQueue__c];
		String query = 'SELECT Id, GoogleAnalyticsHitSettingsName__c, RecordId__c FROM GoogleAnalyticsHitQueue__c WHERE RunInBatch__c = TRUE AND Processed__c = FALSE';
		BatchGoogleAnalyticsHitQueue batchjob = new BatchGoogleAnalyticsHitQueue(query);
		batchjob = new BatchGoogleAnalyticsHitQueue();
		Database.executeBatch(batchjob, 2);
		Test.stopTest();

		System.assertEquals(2, results.size());
		for (GoogleAnalyticsHitQueue__c rqueue: results)
			System.assertEquals(TRUE, rqueue.RunInBatch__c);

		results = [SELECT Id, RunInBatch__c FROM GoogleAnalyticsHitQueue__c where Processed__c = true];
		System.assertEquals(2, results.size());
	}

	private static Lead generateLead(){
		Lead record = new Lead (
			FirstName = 'Name 1',
			LastName = 'Last Name',
			Status = 'Open',
			Company = 'Company'
		);
		return record;
	}

	private static GoogleAnalyticsHitSettings__c generateHitSettings(Id appId){
		GoogleAnalyticsHitSettings__c record = new GoogleAnalyticsHitSettings__c (
			Name = 'leadHitSettings',
			GoogleAnalyticsApp__c = appId
		);
		return record;
	}

	private static GoogleAnalyticsIntegration__c customSettings(){
		GoogleAnalyticsIntegration__c record = new GoogleAnalyticsIntegration__c(
			Name = 'GAv1',
			URLEndpoint__c = 'https://www.google-analytics.com/debug/collect?'
		);
		return record;
	}

	private static GoogleAnalyticsApp__c generateApp(){
		GoogleAnalyticsApp__c record = new GoogleAnalyticsApp__c(
			TrackingID__c = 'UA-12345',
			Name = 'App'
		);
		return record;
	}

	private static APITemplate__c generateTemplate(){
		APITemplate__c record = new APITemplate__c(
				Name = 'Template1',
				ObjectAPIName__c = 'Lead',
				HitType__c = 'item'
		);
		return record;
	}

	private static List<APITemplateFieldMapping__c> generateAPITemplate(Id templateId){
		APITemplateFieldMapping__c record1 = new APITemplateFieldMapping__c(
			APITemplate__c = templateId,
			ExternalFieldName__c = 'ci',
			SalesforceFieldAPIName__c = 'Id'
		);
		APITemplateFieldMapping__c record2 = new APITemplateFieldMapping__c(
			APITemplate__c = templateId,
			ExternalFieldName__c = 'ti',
			SalesforceFieldAPIName__c = 'not_defined',
			DefaultValue__c = '99'
		);
		return new List<APITemplateFieldMapping__c> {record1, record2};
	}

	private static GoogleAnalyticsHitStep__c generateHitSteps(Id templateId, Id hitSettings){
		GoogleAnalyticsHitStep__c record = new GoogleAnalyticsHitStep__c(
			APITemplate__c = templateId,
			GoogleAnalyticsHitSettings__c = hitSettings,
			Order__c = 1
		);
		return record;
	}

	public class GAHttpCalloutMock implements HttpCalloutMock{
	  public HttpResponse respond(HTTPRequest req){
	    HttpResponse res = new HttpResponse();
	    res.setStatus('OK');
	    res.setStatusCode(200);
	    res.setBody('Body');
	    return res;
	  }
	}

}