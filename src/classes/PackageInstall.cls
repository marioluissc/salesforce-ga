global with sharing class PackageInstall
implements InstallHandler
{
		global void onInstall(InstallContext context){
			if(context.previousVersion() == null) {
				createGACustomSettings();
				scheduleBatchJob();
			}
		}

		private void createGACustomSettings(){
			GoogleAnalyticsIntegration__c record = new GoogleAnalyticsIntegration__c(
				Name = 'GAv1',
				URLEndpoint__c = 'https://www.google-analytics.com/collect?'
			);

			GoogleAnalyticsIntegration__c recordDebug = new GoogleAnalyticsIntegration__c(
				Name = 'GAv1_debug',
				URLEndpoint__c = 'https://www.google-analytics.com/debug/collect?'
			);
			Database.insert(new List<GoogleAnalyticsIntegration__c> { record, recordDebug});
		}

		private void scheduleBatchJob(){
			System.schedule('GoogleAnalyticsHitQueue Hourly', '0 0 * * * ?', new BatchGoogleAnalyticsHitQueue() );
		}
}