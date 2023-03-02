global with sharing class ListViewsStylesList extends VisualEditor.DynamicPickList {
	    public static final String DefaultLabel = '--Select--';
		private VisualEditor.DynamicPickListRows values;
		private VisualEditor.DynamicPickListRows getDataRows() {
			if (values == null) {
			    values = new VisualEditor.DynamicPickListRows();
			    values.addrow(new VisualEditor.DataRow(DefaultLabel,null));
			    values.addrow(new VisualEditor.DataRow('Blue','severityBlue'));
			    values.addrow(new VisualEditor.DataRow('Green','severityGreen'));
			    values.addrow(new VisualEditor.DataRow('Yellow','severityYellow'));
			    values.addrow(new VisualEditor.DataRow('Red','severityRed'));
			    values.addrow(new VisualEditor.DataRow('Amber','severityAmber'));
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