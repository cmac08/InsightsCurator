/**
 * Dynamic schema definition for Insight__c fields using Salesforce Schema API
 * Automatically stays in sync with org metadata - no manual updates needed!
 */
public with sharing class InsightFieldSchema {
    
    // Cache the field map to avoid repeated describe calls
    private static Map<String, Schema.SObjectField> fieldMapCache;
    
    /**
     * Returns all accessible Insight__c fields dynamically from org schema
     * Respects field-level security
     */
    public static Set<String> getAllowedFields() {
        Set<String> allowedFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            // Only include fields the user can access
            if (fieldDescribe.isAccessible()) {
                allowedFields.add(fieldDescribe.getName());
            }
        }
        
        return allowedFields;
    }
    
    /**
     * Returns default fields to query when none specified
     * These are the essential fields for UI display
     */
    public static List<String> getDefaultFields() {
        List<String> defaults = new List<String>{
            'Id', 
            'Name',
            'Account__c',
            'Account__r.Name',
            'EDGE_Product_Name__c',
            'Status__c',
            'Likelihood__c',
            'Rank__c',
            'Estimated_Annual_Revenue__c',
            'Insight_Details__c'
        };
        
        // Verify all fields exist and are accessible
        List<String> verifiedDefaults = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        
        for (String fieldName : defaults) {
            if (fieldMap.containsKey(fieldName.toLowerCase())) {
                Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
                if (field.getDescribe().isAccessible()) {
                    verifiedDefaults.add(fieldName);
                }
            }
        }
        
        return verifiedDefaults;
    }
    
    /**
     * Returns field descriptions for AI prompt - dynamically generated from schema
     */
    public static String getFieldDescriptions() {
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        
        List<String> standardFields = new List<String>();
        List<String> customFields = new List<String>();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            // Skip fields user can't access
            if (!fieldDescribe.isAccessible()) {
                continue;
            }
            
            String apiName = fieldDescribe.getName();
            String label = fieldDescribe.getLabel();
            String type = getSimpleType(fieldDescribe.getType());
            
            // Build field description
            String description = '- ' + apiName + ' (' + type + ' - ' + label + ')';
            
            // Add to appropriate list
            if (fieldDescribe.isCustom()) {
                customFields.add(description);
            } else {
                // Only include commonly used standard fields
                if (isUsefulStandardField(apiName)) {
                    standardFields.add(description);
                }
            }
        }
        
        // Sort for consistent ordering
        standardFields.sort();
        customFields.sort();
        
        String result = 'AVAILABLE INSIGHT__C FIELDS (USE ONLY THESE):\n';
        
        if (!standardFields.isEmpty()) {
            result += 'Standard Fields:\n' + String.join(standardFields, '\n') + '\n\n';
        }
        
        if (!customFields.isEmpty()) {
            result += 'Custom Fields:\n' + String.join(customFields, '\n') + '\n\n';
        }
        
        result += getFieldMappingGuidance();
        
        return result;
    }
    
    /**
     * Returns guidance on how to map common terms to actual fields
     */
    private static String getFieldMappingGuidance() {
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        List<String> guidance = new List<String>();
        
        // Build smart mapping guidance based on available fields
        if (hasField(fieldMap, 'Status__c')) {
            guidance.add('- Status__c values: "Open", "Deferred", "Closed", "Archived" - use for workflow status only');
        }
        if (hasField(fieldMap, 'Likelihood__c')) {
            guidance.add('- Likelihood__c values: "Very High", "High", "Medium", "Low" - use for probability/confidence/priority queries');
        }
        if (hasField(fieldMap, 'EDGE_Product_Name__c')) {
            guidance.add('- EDGE_Product_Name__c: Specific product/solution name');
            guidance.add('- IMPORTANT: Normalize solution/product names from plural to singular form before filtering');
            guidance.add('  → Example: input "Commercial Cards" should be simplified to "Commercial Card"');
            guidance.add('  → Example: input "Retail Payments" → "Retail Payment" (remove trailing "s" when appropriate)');
            guidance.add('  → For "commercial card", "product X", "solution Y": filter on EDGE_Product_Name__c');
            guidance.add('  → Example filter: {"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Commercial Card%"}');
        }
        if (hasField(fieldMap, 'Rank__c')) {
            guidance.add('- Rank__c: Numeric ranking (decimal) - use for sorting by importance');
        }
        if (hasField(fieldMap, 'Estimated_Annual_Revenue__c')) {
            guidance.add('- Estimated_Annual_Revenue__c: Revenue amount (text formula) - use for revenue queries');
        }
        if (hasField(fieldMap, 'Account__r.Name')) {
            guidance.add('- Account__c: Account reference - DO NOT compare names to Account__c (it is a lookup Id).');
            guidance.add('- For human/company names with no explicit field, TREAT as Account__r.Name.');
            guidance.add('- Use LIKE with wildcards for proper nouns (name searches).');
            guidance.add('- Example WHERE filters:');
            guidance.add('  → {"field":"Account__r.Name","op":"LIKE","value":"%Acme%"}     (contains)');
            guidance.add('  → {"field":"Account__r.Name","op":"LIKE","value":"Acme%"}      (starts with)');
            guidance.add('  → {"field":"Account__r.Name","op":"=","value":"Acme Corp"}     (exact match)');
            guidance.add('- When users say "for account X" or provide a person/company name (e.g., "Andy Peterson"), map it to Account__r.Name LIKE "%Andy Peterson%".');
            guidance.add('- Only compare Account__c to a Salesforce Id value (15/18-char) when an Id is explicitly provided.');
        }
        if (hasField(fieldMap, 'Shortlist__c')) {
            guidance.add('- Shortlist__c: Boolean checkbox - use for "shortlisted" or "selected" queries');
        }
        if (hasField(fieldMap, 'Insight_Details__c')) {
            guidance.add('- Insight_Details__c: Long text field (details/description) - CANNOT be filtered, only selected for display');
        }
        if (hasField(fieldMap, 'CreatedDate')) {
            guidance.add('- CreatedDate: DateTime field - use date literals (TODAY, THIS_YEAR, LAST_N_DAYS:30) without quotes');
        }
        if (hasField(fieldMap, 'LastModifiedDate')) {
            guidance.add('- LastModifiedDate: DateTime field - use date literals (TODAY, THIS_YEAR, LAST_N_DAYS:30) without quotes');
        }
        
        if (guidance.isEmpty()) {
            return '';
        }
        
        return 'FIELD MAPPING GUIDANCE:\n' + String.join(guidance, '\n') + '\n\n'
            + 'CRITICAL FIELD USAGE RULES:\n'
            + '- For workflow status ("open", "closed", "deferred"): use Status__c with exact values\n'
            + '- For priority/confidence ("high priority", "very high likelihood"): use Likelihood__c\n'
            + '- For product/solution names ("commercial cards", "product X"): use EDGE_Product_Name__c with LIKE\n'
            + '- For importance ranking: use Rank__c (numeric sorting)\n'
            + '- For date queries: use CreatedDate or LastModifiedDate with date literals (no quotes)\n'
            + '- Insight_Details__c is a long text field - it CANNOT be used in filters, only in the fields array\n\n'
            + ' IMPORTANT:\n'
            + '- When users ask about "banking", "commercial cards", "retail" - these are likely in EDGE_Product_Name__c\n'
            + '- Use EDGE_Product_Name__c with LIKE operator for product/industry filtering\n'
            + '- DO NOT filter on Insight_Details__c - Salesforce does not allow filtering long text fields\n'
            + '- DO NOT put quotes around date values - use literals like TODAY, THIS_YEAR\n'
            + '- DO NOT create fields like Category__c, Industry__c, or Priority__c - they do not exist!\n'
            + 'ONLY use fields from the Available Fields list above.';
    }
    
    /**
     * Returns numeric fields (for range queries)
     */
    public static Set<String> getNumericFields() {
        Set<String> numericFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            if (!fieldDescribe.isAccessible()) {
                continue;
            }
            
            Schema.DisplayType fieldType = fieldDescribe.getType();
            if (fieldType == Schema.DisplayType.INTEGER ||
                fieldType == Schema.DisplayType.DOUBLE ||
                fieldType == Schema.DisplayType.CURRENCY ||
                fieldType == Schema.DisplayType.PERCENT) {
                numericFields.add(fieldDescribe.getName());
            }
        }
        
        return numericFields;
    }
    
    /**
     * Returns boolean fields
     */
    public static Set<String> getBooleanFields() {
        Set<String> booleanFields = new Set<String>();
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            if (!fieldDescribe.isAccessible()) {
                continue;
            }
            
            if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                booleanFields.add(fieldDescribe.getName());
            }
        }
        
        return booleanFields;
    }
    
    /**
     * Checks if a field exists and is accessible
     */
    public static Boolean isValidField(String fieldName) {
        if (String.isBlank(fieldName)) {
            return false;
        }
        
        Map<String, Schema.SObjectField> fieldMap = getFieldMap();
        Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
        
        if (field == null) {
            return false;
        }
        
        return field.getDescribe().isAccessible();
    }
    
    /**
     * Checks if a field is numeric
     */
    public static Boolean isNumericField(String fieldName) {
        return getNumericFields().contains(fieldName);
    }
    
    /**
     * Checks if a field is boolean
     */
    public static Boolean isBooleanField(String fieldName) {
        return getBooleanFields().contains(fieldName);
    }
    
    // ===== Private Helper Methods =====
    
    /**
     * Gets and caches the field map for Insight__c
     */
    private static Map<String, Schema.SObjectField> getFieldMap() {
        if (fieldMapCache == null) {
            fieldMapCache = Schema.SObjectType.Insight__c.fields.getMap();
        }
        return fieldMapCache;
    }
    
    /**
     * Checks if a field exists in the field map
     */
    private static Boolean hasField(Map<String, Schema.SObjectField> fieldMap, String fieldName) {
        Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
        return field != null && field.getDescribe().isAccessible();
    }
    
    /**
     * Converts Schema.DisplayType to simple string for AI prompt
     */
    private static String getSimpleType(Schema.DisplayType fieldType) {
        if (fieldType == Schema.DisplayType.STRING || 
            fieldType == Schema.DisplayType.TEXTAREA || 
            fieldType == Schema.DisplayType.PICKLIST) {
            return 'text';
        } else if (fieldType == Schema.DisplayType.INTEGER || 
                   fieldType == Schema.DisplayType.DOUBLE || 
                   fieldType == Schema.DisplayType.LONG) {
            return 'number';
        } else if (fieldType == Schema.DisplayType.CURRENCY) {
            return 'currency';
        } else if (fieldType == Schema.DisplayType.PERCENT) {
            return 'percent';
        } else if (fieldType == Schema.DisplayType.BOOLEAN) {
            return 'boolean';
        } else if (fieldType == Schema.DisplayType.DATE || 
                   fieldType == Schema.DisplayType.DATETIME) {
            return 'date';
        } else if (fieldType == Schema.DisplayType.REFERENCE) {
            return 'reference';
        } else {
            return 'text';
        }
    }
    
    /**
     * Determines if a standard field should be included in AI prompt
     */
    private static Boolean isUsefulStandardField(String fieldName) {
        Set<String> usefulFields = new Set<String>{
            'Id', 'Name', 'CreatedDate', 'CreatedById', 
            'LastModifiedDate', 'LastModifiedById', 'OwnerId'
        };
        return usefulFields.contains(fieldName);
    }
}
