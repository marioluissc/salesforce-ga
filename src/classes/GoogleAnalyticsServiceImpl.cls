public with sharing class GoogleAnalyticsServiceImpl {
	private static GoogleAnalyticsIntegration__c settings {
		get {
			if (settings == null){
				settings = GoogleAnalyticsIntegration__c.getValues(GoogleAnalyticsService.GA_VERSION);
				if (settings == null)
		 			throw new GoogleAnalyticsService.ServiceException('Google Analytics Integration settings not found in Salesforce');
			}
			return settings;
		}
		set;
	}

	public static GoogleAnalyticsHitSettings__c[] getGoogleAnalyticsHitSettings(Set<String> hitSettingsName){
		return [
			SELECT
				Id, Name, GoogleAnalyticsApp__r.TrackingID__c,
				(
					SELECT
						Id, APITemplate__c, APITemplate__r.Id, APITemplate__r.Name, APITemplate__r.ObjectAPIName__c, Order__c
					FROM
						GoogleAnalyticsHitsSteps__r
					ORDER BY
						Order__c asc
				)
			FROM
				GoogleAnalyticsHitSettings__c
			WHERE
				Name in :hitSettingsName
		];
	}

	public static void sendGAHit(List<GoogleAnalyticsService.HitRequest> requests){

		Map<String, Set<Id>> recordIdsByHitSettingsName = getRecordIdsByHitSettingsName(requests);

		Map<Id, GoogleAnalyticsHitSettings__c> hitsSettingsById = new Map<Id, GoogleAnalyticsHitSettings__c>(getGoogleAnalyticsHitSettings(recordIdsByHitSettingsName.keySet()));

		Map<Id, Map<Id, Set<Id>>> recordIdsByTemplateIdByHitSettingsId = getRecordIdsByTemplateIdByHitSettingsId(recordIdsByHitSettingsName, hitsSettingsById.values());

		Set<Id> allTemplateIds = getTemplateIds(hitsSettingsById.values());

		Map<Id, APITemplatesService.APITemplateResult> apiTemplateResultById = APITemplatesService.getAPITemplateResultById(allTemplateIds);

		List<ObjectMessage> objectMessages = buildObjectMessages(recordIdsByTemplateIdByHitSettingsId, apiTemplateResultById, hitsSettingsById);


		Map<Id, Map<String,String>> requestBodyByrecordIdByRequestId = new Map<Id, Map<String,String>>();

		Integer interactions = 0;
		for (GoogleAnalyticsService.HitRequest request : requests) {
			for (ObjectMessage message : objectMessages) {
				Set<Id> recordIds = message.m_recordsById.keyset();
				recordIds.retainAll(request.m_objectIds);
				for (Id recordId : recordIds) {
					interactions++;
					SObject record = message.m_recordsById.get(recordId);
					String body = message.getURL(record.Id);
					if (requestBodyByrecordIdByRequestId.containsKey(request.m_requestId)){
						requestBodyByrecordIdByRequestId.get(request.m_requestId).put(recordId + '##' + String.valueOf(interactions) , body);
					} else {
						requestBodyByrecordIdByRequestId.put(request.m_requestId, new Map<String, String> { recordId + '##' + String.valueOf(interactions) => body } );
					}
					System.debug( 'Record Id: ' + recordId + '##' + String.valueOf(interactions) + ' | URL Parameters : ' + body);
				}
			}
		}
		if (System.isBatch())
			doSend(requestBodyByrecordIdByRequestId);
		else {
			String requestBodyByrecordIdByRequestIdJSON = JSON.serialize(requestBodyByrecordIdByRequestId);
			doSendFuture(requestBodyByrecordIdByRequestIdJSON);
		}
	}

	private static List<ObjectMessage> buildObjectMessages(Map<Id, Map<Id, Set<Id>>> recordIdsByTemplateIdByHitSettingsId, Map<Id, APITemplatesService.APITemplateResult> apiTemplateResultById, Map<Id, GoogleAnalyticsHitSettings__c> hitsSettingsById) {
		List<ObjectMessage> objectMessages = new List<ObjectMessage>();
		for (Id hitSettingsId : recordIdsByTemplateIdByHitSettingsId.keySet()) {
			for (Id templateId : recordIdsByTemplateIdByHitSettingsId.get(hitSettingsId).keyset()){
				APITemplatesService.APITemplateResult template = apiTemplateResultById.get(templateId);
				System.debug('JSON: '+ JSON.serialize(recordIdsByTemplateIdByHitSettingsId.get(hitSettingsId).get(templateId) ));
				List<SObject> sObjectRecords = template.retrieveRecords( recordIdsByTemplateIdByHitSettingsId.get(hitSettingsId).get(templateId));
				System.debug('Template : ' + template.m_apiTemplateObj.Name + ' sObjects Found : '+ sObjectRecords.size());
				if (sObjectRecords.IsEmpty())
					continue;

				ObjectMessage message = new ObjectMessage(sObjectRecords, template, hitsSettingsById.get(hitSettingsId));
				objectMessages.add(message);
			}
		}
		return objectMessages;
	}

	private static Set<Id> getTemplateIds(List<GoogleAnalyticsHitSettings__c> hitsSettings){
		Set<Id> results = new Set<Id>();
		for (GoogleAnalyticsHitSettings__c hitSettings : hitsSettings) {
			for (GoogleAnalyticsHitStep__c step: hitSettings.GoogleAnalyticsHitsSteps__r)
				results.add(step.APITemplate__r.Id);
		}
		return results;
	}

	private static Map<Id, Map<Id, Set<Id>>> getRecordIdsByTemplateIdByHitSettingsId(Map<String, Set<Id>> recordIdsByHitSettingsName, List<GoogleAnalyticsHitSettings__c> hitsSettings) {
		Map<Id, Map<Id, Set<Id>>> results = new Map<Id, Map<Id, Set<Id>>>();
		for (GoogleAnalyticsHitSettings__c hitSettings : hitsSettings) {
			Map<Id, Set<Id>> recordIdsByTemplateId = new Map<Id, Set<Id>>();
			for (GoogleAnalyticsHitStep__c step: hitSettings.GoogleAnalyticsHitsSteps__r) {
				Set<Id> recordIds = filterRecordsIdsforObjectName( recordIdsByHitSettingsName.get(hitSettings.Name), step.APITemplate__r.ObjectAPIName__c);
				recordIdsByTemplateId.put(step.APITemplate__r.Id, recordIds);
			}
			results.put(hitSettings.Id, recordIdsByTemplateId);
		}
		return results;
	}

	private static Map<String, Set<Id>> getRecordIdsByHitSettingsName(List<GoogleAnalyticsService.HitRequest> requests) {
		Map<String, Set<Id>> results = new Map<String, Set<Id>>();
		for (GoogleAnalyticsService.HitRequest request: requests) {
			if (!results.containsKey(request.m_gaHitsettingsName)){
				results.put(request.m_gaHitsettingsName, request.m_objectIds);
			} else {
				results.get(request.m_gaHitsettingsName).addAll(request.m_objectIds);
			}
		}
		return results;
	}

	private static Set<Id> filterRecordsIdsforObjectName(Set<Id> recordIds, String sObjectName){
		Set<Id> results = new Set<Id>();
		for (Id recordId : recordIds) {
			if (!String.valueOf(recordId).substring(0,3).equals(Schema.getGlobalDescribe().get(sObjectName).getDescribe().getKeyPrefix()))
				continue;
			results.add(recordId);
		}
		return results;
	}

	@future(callout=true)
	private static void doSendFuture(String requestBodyByrecordIdByRequestIdJSON ) {
		Map<String, Object> tempRequest = (Map<String, Object>) JSON.deserializeUntyped(requestBodyByrecordIdByRequestIdJSON  );
		Map<Id, Map<String,Object>> requestBodyByrecordIdByRequestId = new Map<Id, Map<String,Object>>();

		for (String requestId : tempRequest.keySet())
			requestBodyByrecordIdByRequestId.put((Id)requestId, (Map<String,Object>)tempRequest.get(requestId));

		doSend(requestBodyByrecordIdByRequestId);
	}


	private static HttpResponse restCall(String body){
		Http http = new Http();
		HttpRequest	restImpl = new HttpRequest();
		restImpl.setEndPoint(settings.URLEndpoint__c);
		restImpl.setMethod('POST');
		restImpl.setBody(body);
		return http.send(restImpl);
	}

	private static void doSend(Map<Id, Map<String,Object>> requestBodyByrecordIdByRequestId){
		Map<Id, Map<String,Boolean>> responseStatusByrecordIdByRequestId = new Map<Id, Map<String,Boolean>>();
		for (Id requestId : requestBodyByrecordIdByRequestId.keySet()) {
			for (String recordId : requestBodyByrecordIdByRequestId.get(requestId).keySet()){
				HttpResponse httpRes = restCall((String)requestBodyByrecordIdByRequestId.get(requestId).get(recordId));
				Boolean isSuccess = (httpRes.getStatusCode() < 200 || httpRes.getStatusCode() >= 300) ? FALSE : TRUE;
				if (responseStatusByrecordIdByRequestId.containsKey(requestId))
					responseStatusByrecordIdByRequestId.get(requestId).put(recordId, isSuccess);
				else
					responseStatusByrecordIdByRequestId.put(requestId, new Map<String, Boolean> { recordId => isSuccess} );
			}
		}

		//Store Result;

		Map<Id,GoogleAnalyticsHitQueue__c> queueById = new Map<Id, GoogleAnalyticsHitQueue__c> ([
			SELECT
				Id, Log__c, Processed__c
			FROM
				GoogleAnalyticsHitQueue__c
			WHERE
				Id IN :responseStatusByrecordIdByRequestId.keySet()
		]);
		List<GoogleAnalyticsHitQueue__c> queuesToUpdate = new List<GoogleAnalyticsHitQueue__c>();
		for (Id requestId : responseStatusByrecordIdByRequestId.keySet()) {
			GoogleAnalyticsHitQueue__c queue = queueById.get(requestId);
			queue.Processed__c = true;
			queue.Log__c = '';
			for (String recordId : responseStatusByrecordIdByRequestId.get(requestId).keySet()){
				queue.Log__c += System.now() + ' | ' + (responseStatusByrecordIdByRequestId.get(requestId).get(recordId) ? '' : 'Hit Not Sent to Google Analytics: ' ) + settings.URLEndpoint__c + requestBodyByrecordIdByRequestId.get(queue.Id).get(recordId) + ' | \n';
			}
			queuesToUpdate.add(queue);
		}

		if (!queuesToUpdate.isEmpty())
			update queuesToUpdate;

	}

	// private static void doSend(Id requestId, String body) {
	// 	try {
	//
	// 		HttpResponse httpRes = restCall(body);
	// 		System.debug(LoggingLevel.DEBUG, 'Status: '+httpRes.getStatus());
	// 		System.debug(LoggingLevel.DEBUG, 'Body: '+httpRes.getBody());
	//
	// 		if (httpRes.getStatusCode() < 200 || httpRes.getStatusCode() >= 300) {
	// 			throw new GoogleAnalyticsService.ServiceException('Error to request Google Analytics API');
	// 		}
	// 		GoogleAnalyticsHitQueue__c[] queueItem = [
	// 			SELECT
	// 				Id, Log__c
	// 			FROM
	// 				GoogleAnalyticsHitQueue__c
	// 			WHERE
	// 				Id = :requestId
	// 		];
	// 		if (!queueItem.isEmpty()) {
	// 			for (GoogleAnalyticsHitQueue__c queue: queueItem) {
	// 				if (queue.Log__c == null) queue.Log__c = '';
	// 				queue.Log__c += System.now() + ' | ' + settings.URLEndpoint__c + body + ' |\n';
	// 				queue.Processed__c = true;
	// 			}
	// 			update queueItem;
	// 		}
	//
	// 	}catch(Exception ex) {
	// 		GoogleAnalyticsHitQueue__c[] queueItem = [
	// 			SELECT
	// 				Id, Log__c
	// 			FROM
	// 				GoogleAnalyticsHitQueue__c
	// 			WHERE
	// 				Id = :requestId
	// 		];
	// 		if (!queueItem.isEmpty()) {
	// 			for (GoogleAnalyticsHitQueue__c queue: queueItem){
	// 				if (queue.Log__c == null) queue.Log__c = '';
	// 				queue.Log__c += System.now() + ' | ' + ex.getMessage() + ' |\n';
	// 				queue.Processed__c = false;
	// 			}
	// 			update queueItem;
	// 		}
	// 	} //return httpRes;
	// }

	@TestVisible
  private abstract class Message {
		public Map<Id, Map<String, String>> paramsByRecordId {
			get {
				if (paramsByRecordId == null) {
					paramsByRecordId = getParamsByRecordId();
				}
				return paramsByRecordId;
			}
			set;
		}
		public String getURL(Id recordId) {
			if (!paramsByRecordId.containsKey(recordId)){
				throw new GoogleAnalyticsService.ServiceException('Record Id not found');
			}

      Map<String, String> params = paramsByRecordId.get(recordId);
      List<String> urlParams = new List<String>();
      for (String p : params.keySet())
        urlParams.add(p + '='+ EncodingUtil.urlEncode( params.get(p), 'UTF-8') );
      return String.join(urlParams, '&');
    }

    protected abstract Map<Id, Map<String, String>> getParamsByRecordId();
    private abstract void validate();
	}

	private class ObjectMessage extends Message {
		public transient Map<Id, SObject> m_recordsById;
		public List<SObject> m_records;
		public APITemplatesService.APITemplateResult m_apiTemplateResult;
		public GoogleAnalyticsHitSettings__c m_hitSettings;

		public ObjectMessage(List<SObject> records, APITemplatesService.APITemplateResult apiTemplateResult, GoogleAnalyticsHitSettings__c hitSettings) {
			m_records = records;
			m_recordsById = new Map<Id, SObject>(m_records);
			m_apiTemplateResult = apiTemplateResult;
			m_hitSettings = hitSettings;
		}

		private virtual override void validate() {
    }

		protected virtual override Map<Id, Map<String, String>> getParamsByRecordId() {
			Map<Id, Map<String, String>> paramsByRecordId = new Map<Id, Map<String, String>> ();
			Map<String, String> params = new Map<String, String>();

			for(SObject record : m_records) {
				params = new Map<String, String>();
				params.put('v', '1');
				params.put('t', m_apitemplateResult.m_apiTemplateObj.HitType__c);
				params.put('tid', m_hitSettings.GoogleAnalyticsApp__r.TrackingID__c);
				for (APITemplateFieldMapping__c field : m_apitemplateResult.apiTemplatefieldMappingByExternalValue.values() ) {
					System.debug('Field Mapping: '+ field);
					String defaltValue = field.DefaultValue__c != null ? field.DefaultValue__c : '';
					if (field.SalesforceFieldAPIName__c != null && m_apitemplateResult.validSalesforceFieldNames.contains(field.SalesforceFieldAPIName__c.toLowerCase())){
						params.put(field.ExternalFieldName__c,
						(record.get(field.SalesforceFieldAPIName__c) != null ? String.valueOf(record.get(field.SalesforceFieldAPIName__c)) : defaltValue ));
					}else{
						params.put(field.ExternalFieldName__c, defaltValue );
					}
				}
				paramsByRecordId.put((Id)record.get('Id'), params);
			}
			return paramsByRecordId;

			// params.put('v','1'); //version
      // String GAUID = m_record.GAUID__c != null && m_record.GAUID__c.startsWith('GA') ? m_record.GAUID__c.right(m_record.GAUID__c.length() - 6) : m_record.GAUID__c;
      // params.put('tid', getSettings((String) m_record.get('RCountry__c')).GoogleAnalyticsID__c); //GA ID / Tracking ID / Property ID.
      // params.put('cid', m_record.GAUID__c != null ? GAUID : m_record.Id); // Anonymous Client ID/ GAUID Field in SF
      // params.put('t', 'event'); // Transaction hit type.
      // params.put('ea',  m_record.CourseCodeWeb__c != null ?  m_record.CourseCodeWeb__c : m_record.Course__r.CourseCode__c); // Course Code : eg. E1111
      // if (getGeoId(m_record.Country, m_record.State) != null)
      //   params.put('geoid', getGeoId(m_record.Country, m_record.State));
      //return params;
    }
  }
}