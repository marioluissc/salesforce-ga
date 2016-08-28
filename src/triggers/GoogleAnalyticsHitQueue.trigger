trigger GoogleAnalyticsHitQueue on GoogleAnalyticsHitQueue__c (before insert, after insert) {
  List<GoogleAnalyticsService.HitRequest> requests = new List<GoogleAnalyticsService.HitRequest>();
  if (Trigger.isBefore && Trigger.new.size() > 1 ) {
    for (GoogleAnalyticsHitQueue__c queue : Trigger.new){
      queue.RunInBatch__c = TRUE;
    }
  }
  if (Trigger.isAfter && Trigger.new.size() == 1) {
    for (GoogleAnalyticsHitQueue__c queue: Trigger.new) {
      GoogleAnalyticsService.HitRequest request = new GoogleAnalyticsService.HitRequest(
        queue.Id,
        queue.GoogleAnalyticsHitSettingsName__c,
        new set<Id> {queue.RecordId__c }

      );
      requests.add(request);
    }
    GoogleAnalyticsService.sendGAHit(requests);
  }

}