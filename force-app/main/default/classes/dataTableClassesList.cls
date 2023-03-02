global with sharing class dataTableClassesList extends VisualEditor.DynamicPickList{
    public static final String DefaultLabel = '--Select--';
	private VisualEditor.DynamicPickListRows  values;
	private VisualEditor.DynamicPickListRows getDataRows() {
	    if ( values == null ) {
		    values = new VisualEditor.DynamicPickListRows();
		    values.addrow(new VisualEditor.DataRow(DefaultLabel,null));
		    values.addrow(new VisualEditor.DataRow('x-short','x-short'));
		    values.addrow(new VisualEditor.DataRow('short','short'));
		    values.addrow(new VisualEditor.DataRow('medium','medium'));
		    values.addrow(new VisualEditor.DataRow('long','long'));
		    values.addrow(new VisualEditor.DataRow('x-long','x-long'));
	    }
	    
	    return values;
	}



	global override VisualEditor.DataRow getDefaultValue(){
	    return getDataRows().get(0);
	}

	global override VisualEditor.DynamicPickListRows getValues() {
	    return getDataRows();
	}
}