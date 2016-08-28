@isTest
private class GoogleAnalyticsHitQueueTest
{

    @isTest
    static void triggerTest()
    {
      Lead lead = generateLead();
      insert lead;
      GoogleAnalyticsHitQueue__c hitQueue = generatehitQueue();
      hitQueue.RecordId__c = lead.Id;
      Test.starttest();
      insert hitQueue;
      Test.stopTest();
    }

    private static GoogleAnalyticsHitQueue__c generatehitQueue(){
      GoogleAnalyticsHitQueue__c record = new GoogleAnalyticsHitQueue__c(
        GoogleAnalyticsHitSettingsName__c = 'leadSettings'
      );
      return record;
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
}