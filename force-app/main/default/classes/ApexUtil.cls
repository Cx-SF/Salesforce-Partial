public with sharing class ApexUtil {
	private static Boolean enableLog = false;
	private static Integer collectionLogLimit = 50;

	public static Integer countRecordsOfListView(String lwId, String objName) {
		//UP TO 10000
	    try{
		    try {
		      	ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(Database.getQueryLocator('SELECT id FROM ' + objName + ' limit 1'));
		      	ctrl.setFilterId(Id.valueOf(lwId));
			  	throw new CountException(''+ctrl.getResultSize());    
		    } catch (CountException ex) {
		        return Integer.valueOf(ex.getMessage());
		    } catch (Exception ex) {
		        return 0;
		    }
		} catch (Exception ex){
			return 0;
		}
	}
	public static Integer GitHubTest(String lwId) {
		//UP TO 10000
	    try{
			system.debug(lwId);
		} catch (Exception ex){
			return 0;
		}
	}


	private class MyPickListInfo {
		private String validFor;
	}

	public static Map<String, List<Schema.PicklistEntry>> getFieldDependencies(String objectName, String controllingField, String dependentField) {
		Map<String, List<Schema.PicklistEntry>> controllingInfo = new Map<String, List<Schema.PicklistEntry>>();

		Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

		Schema.DescribeSObjectResult describeResult = objType.getDescribe();
		Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
		Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();

		List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
		List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

		for (Schema.PicklistEntry currControllingValue : controllingValues) {
			//System.debug('ControllingField: Label:' + currControllingValue.getLabel());
			controllingInfo.put(currControllingValue.getLabel(), new List<Schema.PicklistEntry>());
		}

		for (Schema.PicklistEntry currDependentValue : dependentValues) {
			String jsonString = JSON.serialize(currDependentValue);

			MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);

			String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();

			//System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);

			Integer baseCount = 0;

			for (Integer curr : hexString.getChars()) {
				Integer val = 0;

				if (curr >= 65) {
					val = curr - 65 + 10;
				} else {
					val = curr - 48;
				}

				if ((val & 8) == 8) {
					//System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
					controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue);
				}
				if ((val & 4) == 4) {
					//System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
					controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue);
				}
				if ((val & 2) == 2) {
					//System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
					controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue);
				}
				if ((val & 1) == 1) {
					//System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
					controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue);
				}

				baseCount += 4;
			}
		}

		System.debug('ControllingInfo: ' + controllingInfo);

		return controllingInfo;
	}

	public static void enableLog() {
		enableLog = true;
	}

	public static void disableLog() {
		enableLog = false;
	}

	public static void setCollectionLogLimit(Integer n) {
		collectionLogLimit = n;
	}

	public static void log(String TAG, String message){
		if (enableLog) {
			Integer line = getCodeLine();
			String l = (line == null)? '' : '[' + line + ']';
			System.debug( l + ' ' + TAG + ' : ' + message);
		}
	}

	public static void log (String TAG, String obj, Object rec) {
		if (enableLog) {
			log(TAG, obj, rec, getCodeLine());
		}	
	}

	public static void log(String TAG, String obj, Object rec, Integer line){
		if (enableLog) {
			try {
				String l = (line == null)? '' : '[' + line + ']';
				System.debug(l + ' '+TAG + ' : '+ ' --'+ obj + ' : ' + rec );
				if (rec instanceof Map<String, SObject> || rec instanceof Map<Id, SObject> ) {
					Map<String, Object> objects = (Map<String, SObject>) rec;
					Integer i =0;
					for (String s : objects.keySet()) {
						if ( i < collectionLogLimit) {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + '--['+s+']' + objects.get(s).toString() );
						} else {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj  + 'Log Limit Exceeded. Size= ' + objects.size());
							break;
						}
						i++;
					}
				} else if (rec instanceof Map<String, Object> ) {
					Map<String, Object> objects = (Map<String, Object>) rec;
					Integer i =0;
					for (String s : objects.keySet()) {
						if ( i < collectionLogLimit) {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + '--['+s+']' + objects.get(s).toString() );
						} else {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj  + 'Log Limit Exceeded. Size= ' + objects.size());
							break;
						}
						i++;
					}
				} else
				if (rec instanceof List<Object> ) {
					List<Object> objects = (List<Object>) rec;
					Integer i =0;
					for (Object o : objects) {
						if ( i < collectionLogLimit) {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + '-- ['+i+']' + o.toString() );
						} else {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + 'Log Limit Exceeded. Size= ' + objects.size());
							break;
						}
						i++;
					}
				} else if (rec instanceof Set<Object>) {
					Set<Object> objects = (Set<Object>) rec;
					Integer i =0;
					for (Object o : objects) {
						if ( i < collectionLogLimit) {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + '-- ['+i+']' + o.toString() );
						} else {
							System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + 'Log Limit Exceeded. Size= ' + objects.size());
							break;
						}
						i++;
					}

				} else {
					//System.debug( l + ' '+TAG + ' : '+ ' --'+ obj + '-- ' + rec.toString());
				}
			} catch (Exception ex) {
				System.debug('Log Exception : ' + ex.getMessage());
			}
		} 

	}

	public static Integer getCodeLine() {
		try {
		    try {
		       	Integer i = 0/0;
		    } catch(Exception e) {
		    	String[] lines = e.getStackTraceString().split('\n'); 
		        String line2 = lines[2];
		        Pattern patt = Pattern.compile('([a-z0-9_.]+): line (\\d+)');
		        Matcher match = patt.matcher(line2);
		        match.find();
		        return Integer.valueOf(match.group(2));
		    }
	    } catch (Exception ex) {
	    	return null;
	    }
	    return null;
	}
	private class LineCodeReceiveException extends Exception {}
	private class CountException extends Exception{}

}