global with sharing class ListViewsList extends VisualEditor.DynamicPickList{
    public static final String DefaultLabel = '--Select--';
	private VisualEditor.DynamicPickListRows  values;
	private VisualEditor.DynamicPickListRows getDataRows() {
	    if ( values == null ) {
		    values = new VisualEditor.DynamicPickListRows();
		    values.addrow(new VisualEditor.DataRow(DefaultLabel,null));
		    Map<String, Schema.SObjectType> objectsApiTypes = Schema.getGlobalDescribe();
		    List<ListView> listViews = [SELECT  Id,
		    				Name,
		    				DeveloperName,
		    				NamespacePrefix,
		    				SobjectType,
		    				IsSoqlCompatible,
		    				CreatedDate,
		    				CreatedBy.Name,
		    				LastModifiedDate,
		    				LastModifiedBy.Name,
		    				LastViewedDate,
		    				LastReferencedDate
		     		FROM ListView 
		     		WHERE SobjectType IN:objectsApiTypes.keyset() 
		     		ORDER BY SobjectType];
		    System.debug(objectsApiTypes);
		    for (ListView lw : listViews ) {
		    	String sobjectName = ( objectsApiTypes.get(lw.SobjectType.tolowercase()) != null ) ? objectsApiTypes.get(lw.SobjectType.tolowercase()).getDescribe().getName() : lw.SobjectType;
		    	values.addrow(new VisualEditor.DataRow(sobjectName + ':' + lw.Name , lw.Id + '=#=' + sobjectName + '=#=' + lw.Name + '=#=' + lw.SobjectType));
		    }
	    }
	    
	    return Values;
	}



	global override VisualEditor.DataRow getDefaultValue(){
	    return getDataRows().get(0);
	}

	global override VisualEditor.DynamicPickListRows getValues() {
	    return getDataRows();
	}
}