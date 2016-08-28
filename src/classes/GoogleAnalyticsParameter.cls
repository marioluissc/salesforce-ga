public class GoogleAnalyticsParameter{
	public HitTypes[] hitTypes;

	public static GoogleAnalyticsParameter parse(String json){
		return (GoogleAnalyticsParameter) System.JSON.deserialize(json, GoogleAnalyticsParameter.class);
	}

	public Map<String, List<Fields>> fieldsByEventName() {
		Map<String, List<Fields>> fieldsByEventName = new Map<String, List<Fields>>();
		for (HitTypes hit : this.hitTypes){
			fieldsByEventName.put(hit.name, hit.fields);
		}
		return fieldsByEventName;
	}

	public class HitTypes {
		public String name;	//event
		public fields[] fields;
	}
	public class Fields {
		public String label;	//Client Id
		public String key;	//cid
		public boolean required;
	}
}