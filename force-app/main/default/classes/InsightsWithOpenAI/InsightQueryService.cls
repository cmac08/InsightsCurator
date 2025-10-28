/**
 * Secure query execution service for Insight__c records
 * Validates, normalizes, and executes structured queries with security controls
 */
public with sharing class InsightQueryService {
    
    // Security constants
    private static final Integer MAX_LIMIT = 200;
    private static final Integer DEFAULT_LIMIT = 50;
    private static final String REQUIRED_OBJECT = 'Insight__c';
    
    /**
     * Main execution method - validates, normalizes, and executes the query
     * @param query Structured query from OpenAI
     * @return List of Insight__c records matching the query
     */
    public static List<Insight__c> execute(OpenAIStructuredQuery.StructuredQuery query) {
        try {
            // Step 1: Validate the query structure
            validateQuery(query);
            
            // Step 2: Normalize and apply security rules
            OpenAIStructuredQuery.StructuredQuery normalizedQuery = normalize(query);
            
            // Step 3: Build secure SOQL
            String soql = normalizedQuery.toSOQL();
            System.debug('=== Executing SOQL ===');
            System.debug(soql);
            
            // Step 4: Execute and return results
            List<Insight__c> results = Database.query(soql);
            System.debug('Query returned ' + results.size() + ' record(s)');
            
            return results;
            
        } catch (QueryException e) {
            throw e;
        } catch (Exception e) {
            throw new QueryServiceException(
                'Failed to execute query: ' + e.getMessage(),
                e
            );
        }
    }
    
    /**
     * Validates basic query structure
     */
    private static void validateQuery(OpenAIStructuredQuery.StructuredQuery query) {
        if (query == null) {
            throw new QueryServiceException('Query cannot be null');
        }
        
        if (String.isBlank(query.objectName)) {
            throw new QueryServiceException('Query must specify an object name');
        }
        
        if (query.objectName != REQUIRED_OBJECT) {
            throw new QueryServiceException(
                'Only ' + REQUIRED_OBJECT + ' queries are supported. Got: ' + query.objectName
            );
        }
    }
    
    /**
     * Normalizes and secures the query
     * - Enforces field whitelist
     * - Caps record limits
     * - Validates operators and sort orders
     * - Removes invalid filters
     */
    public static OpenAIStructuredQuery.StructuredQuery normalize(
        OpenAIStructuredQuery.StructuredQuery query
    ) {
        // Normalize limit
        query.limit_x = normalizeLimit(query.limit_x);
        
        // Normalize and validate fields
        query.fields = normalizeFields(query.fields);
        
        // Normalize and validate filters
        if (query.filters != null && !query.filters.isEmpty()) {
            query.filters = normalizeFilters(query.filters);
        }
        
        // Validate range
        if (query.range_x != null) {
            if (!isAllowedField(query.range_x.field)) {
                System.debug('Removing invalid range field: ' + query.range_x.field);
                query.range_x = null;
            }
        }
        
        // Validate sort
        if (query.sort_x != null) {
            if (!isAllowedField(query.sort_x.field)) {
                System.debug('Removing invalid sort field: ' + query.sort_x.field);
                query.sort_x = null;
            } else if (!isAllowedSortOrder(query.sort_x.order_x)) {
                System.debug('Invalid sort order, defaulting to ASC');
                query.sort_x.order_x = 'ASC';
            }
        }
        
        return query;
    }
    
    /**
     * Normalizes the record limit
     */
    private static Integer normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null || requestedLimit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(requestedLimit, MAX_LIMIT);
    }
    
    /**
     * Normalizes and validates fields list
     */
    private static List<String> normalizeFields(List<String> fields) {
        // Always include these essential fields for UI display
        Set<String> essentialFields = new Set<String>{
            'Id',
            'Name',
            'Account__c',
            'Account__r.Name',
            'EDGE_Product_Name__c',
            'Status__c',
            'Likelihood__c',
            'Rank__c',
            'Estimated_Annual_Revenue__c'
        };
        
        Set<String> fieldSet = new Set<String>();
        
        if (fields == null || fields.isEmpty()) {
            // Return essential fields plus commonly used ones
            return getDefaultFields();
        }
        
        // Start with essential fields
        for (String essentialField : essentialFields) {
            if (isAllowedField(essentialField)) {
                fieldSet.add(essentialField);
            }
        }
        
        // Add requested fields if valid
        for (String field : fields) {
            if (String.isNotBlank(field) && isAllowedField(field)) {
                fieldSet.add(field);
            } else {
                System.debug('Filtered out invalid field: ' + field);
            }
        }
        
        return new List<String>(fieldSet);
    }
    
    /**
     * Returns default fields when none specified
     */
    private static List<String> getDefaultFields() {
        return new List<String>{
            'Id',
            'Name',
            'Account__c',
            'Account__r.Name',
            'EDGE_Product_Name__c',
            'Likelihood__c',
            'Estimated_Annual_Revenue__c',
            'Rank__c',
            'Status__c'
        };
    }
    
    /**
     * Normalizes and validates filters
     */
    private static List<OpenAIStructuredQuery.Filter> normalizeFilters(
        List<OpenAIStructuredQuery.Filter> filters
    ) {
        List<OpenAIStructuredQuery.Filter> validFilters = new List<OpenAIStructuredQuery.Filter>();
        
        for (OpenAIStructuredQuery.Filter filter : filters) {
            if (filter == null) {
                continue;
            }
            
            // Validate field
            if (String.isBlank(filter.field) || !isAllowedField(filter.field)) {
                System.debug('Filtered out invalid filter field: ' + filter.field);
                continue;
            }
            
            // Check if field is filterable (not a long text area)
            if (!isFilterableField(filter.field)) {
                System.debug('Filtered out non-filterable field: ' + filter.field + ' (long text fields cannot be filtered)');
                continue;
            }
            
            // Validate operator
            if (String.isBlank(filter.op) || !isAllowedOperator(filter.op)) {
                System.debug('Filtered out invalid operator: ' + filter.op);
                continue;
            }
            
            // Normalize operator to uppercase
            filter.op = filter.op.trim().toUpperCase();
            
            // Validate value is not null (unless checking for NULL explicitly)
            if (filter.value == null) {
                System.debug('Filtered out filter with null value for field: ' + filter.field);
                continue;
            }
            
            validFilters.add(filter);
        }
        
        return validFilters;
    }
    
    /**
     * Checks if a field can be used in WHERE clause filters
     * Long text area fields cannot be filtered in SOQL
     */
    private static Boolean isFilterableField(String fieldName) {
        if (String.isBlank(fieldName)) {
            return false;
        }
        
        // Support relationship field Account__r.Name explicitly since it's not present in the Insight__c fields map
        if (fieldName == 'Account__r.Name') {
            // Account name is filterable (text)
            return true;
        }
        
        // Get field type
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Insight__c.fields.getMap();
        Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
        
        if (field == null) {
            return false;
        }
        
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        Schema.DisplayType fieldType = fieldDescribe.getType();
        
        // Long text area and rich text area fields cannot be filtered
        if (fieldType == Schema.DisplayType.TEXTAREA && fieldDescribe.getLength() > 255) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Whitelist of allowed Insight__c fields
     * IMPORTANT: Keep this in sync with the field list in OpenAIRequestBuilder
     */
    private static Boolean isAllowedField(String fieldName) {
        if (String.isBlank(fieldName)) {
            return false;
        }
        
        // Comprehensive whitelist of Insight__c fields
        // These MUST match the actual Salesforce object fields
        Set<String> allowedFields = new Set<String>{
            // Standard fields
            'Id',
            'Name',
            'CreatedDate',
            'CreatedById',
            'LastModifiedDate',
            'LastModifiedById',
            'OwnerId',
            
            // Custom fields - ONLY fields that actually exist in the org
            'Account__c',
            'Account__r.Name',
            'EDGE_Product_Name__c',
            'Likelihood__c',
            'Estimated_Annual_Revenue__c',
            'Estimated_Annual_Revenue_Min__c',
            'Estimated_Annual_Revenue_Max__c',
            'Average_Annual_Revenue__c',
            'Rank__c',
            'Shortlist__c',
            'Status__c',
            'Insight_Details__c'
        };
        
        return allowedFields.contains(fieldName);
    }
    
    /**
     * Whitelist of allowed SOQL operators
     */
    private static Boolean isAllowedOperator(String operator) {
        if (String.isBlank(operator)) {
            return false;
        }
        
        Set<String> allowedOperators = new Set<String>{
            '=', '!=', '>', '>=', '<', '<=', 'IN', 'NOT IN', 'LIKE'
        };
        
        return allowedOperators.contains(operator.trim().toUpperCase());
    }
    
    /**
     * Validates sort order
     */
    private static Boolean isAllowedSortOrder(String order) {
        if (String.isBlank(order)) {
            return false;
        }
        
        String upperOrder = order.trim().toUpperCase();
        return upperOrder == 'ASC' || upperOrder == 'DESC';
    }
    
    /**
     * Custom exception for query service errors
     */
    public class QueryServiceException extends Exception {}
    
    /**
     * Custom exception for query execution errors
     */
    public class QueryException extends Exception {}
}
