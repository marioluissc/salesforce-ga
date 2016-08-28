@isTest
public with sharing class GoogleAnalyticsParameterTest {
	@isTest
	static void testParse() {
		String json=		'{'+
		'  "hitTypes" :[{'+
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
		'  },'+
		'  {'+
		'    "name" : "all",'+
		'    "fields" : ['+
		'      {"label": "Data Source", "key" : "ds", "required" : false},'+
		'      {"label": "IP Override", "key" : "uip", "required" : false},'+
		'      {"label": "Geographical Override", "key" : "geoid", "required" : false},'+
		'      {"label": "Anonymize IP", "key" : "aip", "required" : false}'+
		'    ]'+
		'  }'+
		'  ]'+
		'}';
		GoogleAnalyticsParameter obj = GoogleAnalyticsParameter.parse(json);
		obj.fieldsByEventName();
		System.assert(obj != null);
	}
}