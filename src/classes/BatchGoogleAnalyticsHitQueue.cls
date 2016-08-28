global class BatchGoogleAnalyticsHitQueue implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts {

	String m_query;

	global BatchGoogleAnalyticsHitQueue() {
		m_query = 'SELECT Id, GoogleAnalyticsHitSettingsName__c, RecordId__c FROM GoogleAnalyticsHitQueue__c WHERE RunInBatch__c = TRUE AND Processed__c = FALSE ';
	}

	global BatchGoogleAnalyticsHitQueue(String query) {
		m_query = query;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(m_query);
	}

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<GoogleAnalyticsService.HitRequest> requests = new List<GoogleAnalyticsService.HitRequest>();
		for (GoogleAnalyticsHitQueue__c queue: (List<GoogleAnalyticsHitQueue__c>) scope ) {
      GoogleAnalyticsService.HitRequest request = new GoogleAnalyticsService.HitRequest(
        queue.Id,
        queue.GoogleAnalyticsHitSettingsName__c,
        new set<Id> {queue.RecordId__c }

      );
      requests.add(request);
    }
		if (!requests.isEmpty())
    	GoogleAnalyticsService.sendGAHit(requests);
	}

	global void finish(Database.BatchableContext BC) {

	}

	//schedulabe
	global void execute(SchedulableContext ctx){
		Database.executeBatch(new BatchGoogleAnalyticsHitQueue(), 1);
	}

}