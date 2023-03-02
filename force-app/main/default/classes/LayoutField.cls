public class LayoutField {
    
    /******************************************************************************
    Name: LayoutField.apxc
    Description: Apex class for DynamicLayoutDialog field implementation
    
    Change History:
    
    Name			Date			Comments
    -------------------------------------------------------------------------------
    Alex Levchenko 	27-Mar-2019		Initial version
    
    *******************************************************************************/    
	public Boolean isRequired;
    private String label;
    private Integer appearanceOrder;
    private String objectApiName;
    private String fieldApiName;
    private String displayCondition;
	private String conditionalRequired;
    private boolean isAccessible;
    private String dataType;
    private String referenceObject;
    private List<String> picklistValues;
    private String helpText;
    private String defaultValue;
    private String defaultValueStatus;
    private boolean useAutosuggest;
    private String fieldValue;
    
    public LayoutField() {
        this.objectApiName = null;
        this.fieldApiName = null;
    }
    
    public LayoutField(String sObjectApiName, String fieldApiName) {
        this.objectApiName = sObjectApiName;
        this.fieldApiName = fieldApiName;
    }
    
    /*
    public String getOrigFieldDataType() {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(this.objectApiName).getDescribe().fields.getMap();
        for(Schema.SObjectField ft : fieldMap.values()) {
            Schema.DescribeFieldResult fd = ft.getDescribe();
            if (fd.getName() == this.fieldApiName) {
                String dataType = String.ValueOf(fd.getType());
                if (dataType == 'REFERENCE') {
                    dataType = 'LOOKUP';
                }
                return dataType;
            }            
        }
        return null;
    }
    
    public String getOrigLookupReferenceObject() {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(this.objectApiName).getDescribe().fields.getMap();
        for(Schema.SObjectField ft : fieldMap.values()) {
            Schema.DescribeFieldResult fd = ft.getDescribe();
            if (fd.getName() == this.fieldApiName) {
                String dataType = String.ValueOf(fd.getType());
                if (dataType == 'REFERENCE') {
                    return String.ValueOf(fd.getReferenceTo()).replace('(', '').replace(')', '');
                }
            }            
        }
        return null;
    }
    
    public List<String> getOrigPicklistValues() {
        List<String> res = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(this.objectApiName).getDescribe().fields.getMap();
        for (Schema.SObjectField ft : fieldMap.values()) {
            Schema.DescribeFieldResult fd = ft.getDescribe();
            if (fd.getName() == this.fieldApiName) {
                String dataType = String.ValueOf(fd.getType());
                if (dataType == 'PICKLIST') {
                    List<Schema.PicklistEntry> ple = fd.getPicklistValues();
                    for(Schema.PicklistEntry f : ple)
                    {
                        res.add(f.getValue());
                    }
               }
            }            
        }
        return res;
    }
    
    public void setOrigFiledProperties() {
        if (this.objectApiName != null && this.fieldApiName != null) {
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(this.objectApiName).getDescribe().fields.getMap();
            for (Schema.SObjectField ft : fieldMap.values()) {
                Schema.DescribeFieldResult fd = ft.getDescribe();
                if (fd.getName() == this.fieldApiName) {
                    this.label = String.ValueOf(fd.getLabel());
                    String dataType = String.ValueOf(fd.getType());
                    this.dataType = dataType;
                    this.isAccessible = Boolean.ValueOf(fd.isAccessible());
                    this.helpText = fd.getInlineHelpText();
                    if (dataType == 'REFERENCE') {
                        this.dataType = 'LOOKUP';
                        this.referenceObject = String.ValueOf(fd.getReferenceTo()).replace('(', '').replace(')', '');
                    } else if (dataType == 'PICKLIST') {
                        List<String> res = new List<String>();
                        List<Schema.PicklistEntry> ple = fd.getPicklistValues();
                        for(Schema.PicklistEntry f : ple) {
                            res.add(f.getValue());
                        }
                        this.picklistValues = res;
                    }
                }
            }
        }
    }
	*/
    
    public String getLabel() {
        return this.label;
    }
    
    public Integer getAppearanceOrder() {
        return this.appearanceOrder;
    }
    
    public String getObjectApiName() {
        return this.objectApiName;
    }
    
    public String getFieldApiName() {
        return this.fieldApiName;
    }
    
    public String getDisplayCondition() {
        return this.displayCondition;
    }

	public String getConditionalRequired() {
        return this.conditionalRequired;
    }
    
    public String getDataType() {
        return this.dataType;
    }
    
    public String getReferenceObject() {
        return this.referenceObject;
    }
    
    public boolean isAccessible() {
        return this.isAccessible;
    }
    
    public List<String> getPicklistValues() {
        return this.picklistValues;
    }
    
    public String getHelpText() {
        return this.helpText;
    }
    
    public String getDefaultValue() {
        return this.defaultValue;
    }
    
    public String getFieldValue() {
        return this.fieldValue;
    }
    
    public String getDefaultValueStatus() {
        return this.defaultValueStatus;
    }
    
    public boolean isUseAutosuggest() {
        return this.useAutosuggest;
    }

    
    public void setLabel(String label) {
        this.label = label;
    }
    
    public void setAppearanceOrder(Integer appearanceOrder) {
        this.appearanceOrder = appearanceOrder;
    }
    
    public void setObjectApiName(String objectApiName) {
        this.objectApiName = objectApiName;
    }
    
    public void setFieldApiName(String fieldApiName) {
        this.fieldApiName = fieldApiName;
    }
    
    public void setDisplayCondition(String displayCondition) {
        this.displayCondition = displayCondition;
    }

	public void setConditionalRequired(String conditionalRequired) {
        this.conditionalRequired = conditionalRequired;
    }
    
    public void setDataType(String dataType) {
        this.dataType = dataType;
    }
    
    public void setReferenceObject(String referenceObject) {
        this.referenceObject = referenceObject;
    }
    
    public void setPicklistValues(List<String> picklistValues) {
        this.picklistValues = picklistValues;
    }
    
    public void setIsAccessible(boolean isAccessible) {
        this.isAccessible = isAccessible;
    }
    
    public void setHelpText(String helpText) {
        this.helpText = helpText;
    }
    
    public void setDefaultValue(String defaultValue) {
        this.defaultValue = defaultValue;
    }
    
    public void setFieldValue(String fieldValue) {
        this.fieldValue = fieldValue;
    }
    
    public void setDefaultValueStatus(String defaultValueStatus) {
        this.defaultValueStatus = defaultValueStatus;
    }
    
    public void setUseAutosuggest(boolean useAutosuggest) {
        this.useAutosuggest = useAutosuggest;
    }
    
}