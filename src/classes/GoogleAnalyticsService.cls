public with sharing class GoogleAnalyticsService {
	public static String GA_VERSION = 'GAv1';
	public static String GA_DEBUG = GA_VERSION + 'debug';

	public static void sendGAHit(List<GoogleAnalyticsService.HitRequest> requests){
		GoogleAnalyticsServiceImpl.sendGAHit(requests);
	}

	public class HitRequest{
		public String m_gaHitsettingsName {get;set;}
		public Id m_requestId {get;set;}
		public Set<Id> m_objectIds {get;set;}
		public String logs;

		public HitRequest(Id requestId, String gaHitsettingsName, Set<Id> objectIds){
			m_gaHitsettingsName = gaHitsettingsName;
			m_objectIds = objectIds;
			m_requestId = requestId;
			logs = '';
		}

		// public void log(String log){
		// 	logs += System.now() + ' | ' + log + ' |\n';
		// }

		// public void saveLogs(){
		// 	GoogleAnalyticsHitQueue__c queue = new GoogleAnalyticsHitQueue__c(
		// 		Id = m_requestId,
		// 		Log__c = logs,
		// 		Processed__c = true
		// 	);
		// 	update queue;
		// }
	}


	/*
		Response from GA for Debug
	*/
	public class HitResponse{
		public List<HitParsingResult> hitParsingResult;
	}
	public class HitParsingResult {
    public Boolean valid;
    public String hit;
    public List<ParserMessage> parserMessage;
  }
	public class ParserMessage {
    public String messageType;
    public String description;
    public String parameter;
  }

	public class ServiceException extends Exception{

	}
}