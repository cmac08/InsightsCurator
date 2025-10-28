/**
 * Data Transfer Objects for structured queries
 * Represents the expected JSON structure from OpenAI
 */
public with sharing class OpenAIStructuredQuery {
    
    /**
     * Main query specification
     */
    public class StructuredQuery {
        @AuraEnabled public String objectName;
        @AuraEnabled public List<Filter> filters;
        @AuraEnabled public QueryRange range_x;
        @AuraEnabled public SortSpec sort_x;
        @AuraEnabled public Integer limit_x;
        @AuraEnabled public List<String> fields;
        
        /**
         * Converts to a SOQL query string
         * @return Dynamic SOQL query based on the structured query
         */
        public String toSOQL() {
            // Build SELECT clause
            String selectClause = 'SELECT ' + String.join(fields, ', ');
            
            // Build FROM clause
            String fromClause = 'FROM ' + objectName;
            
            // Build WHERE clause
            String whereClause = buildWhereClause();
            
            // Build ORDER BY clause
            String orderByClause = '';
            if (sort_x != null && String.isNotBlank(sort_x.field)) {
                String sortOrder = String.isNotBlank(sort_x.order_x) ? sort_x.order_x : 'ASC';
                orderByClause = 'ORDER BY ' + sort_x.field + ' ' + sortOrder;
            }
            
            // Build LIMIT clause
            String limitClause = '';
            if (limit_x != null && limit_x > 0) {
                limitClause = 'LIMIT ' + limit_x;
            }
            
            // Combine all clauses
            List<String> clauses = new List<String>{
                selectClause,
                fromClause
            };
            
            if (String.isNotBlank(whereClause)) {
                clauses.add(whereClause);
            }
            if (String.isNotBlank(orderByClause)) {
                clauses.add(orderByClause);
            }
            if (String.isNotBlank(limitClause)) {
                clauses.add(limitClause);
            }
            
            return String.join(clauses, ' ');
        }
        
        /**
         * Builds WHERE clause from filters and range
         */
        private String buildWhereClause() {
            List<String> conditions = new List<String>();
            
            // Add filter conditions
            if (filters != null && !filters.isEmpty()) {
                for (Filter f : filters) {
                    // Normalize improper Account name comparisons:
                    // If field is Account__c and value is a non-Id string, convert to Account__r.Name LIKE '%value%'
                    if (f != null && f.field == 'Account__c' && f.value instanceof String) {
                        String stringValue = (String) f.value;
                        // Simple Id heuristic: 15 or 18 char alphanumeric (Salesforce Id)
                        Boolean looksLikeId = stringValue != null && (
                            Pattern.matches('^[a-zA-Z0-9]{15}$', stringValue) ||
                            Pattern.matches('^[a-zA-Z0-9]{18}$', stringValue)
                        );
                        if (!looksLikeId) {
                            Filter nameFilter = new Filter();
                            nameFilter.field = 'Account__r.Name';
                            nameFilter.op = 'LIKE';
                            nameFilter.value = '%' + stringValue + '%';
                            conditions.add(nameFilter.toCondition());
                            continue;
                        }
                    }
                    conditions.add(f.toCondition());
                }
            }
            
            // Add range condition
            if (range_x != null && String.isNotBlank(range_x.field)) {
                conditions.add(range_x.toCondition());
            }
            
            if (conditions.isEmpty()) {
                return '';
            }
            
            return 'WHERE ' + String.join(conditions, ' AND ');
        }
    }
    
    /**
     * Filter condition
     */
    public class Filter {
        @AuraEnabled public String field;
        @AuraEnabled public String op;
        @AuraEnabled public Object value;
        
        /**
         * Converts filter to SOQL condition
         */
        public String toCondition() {
            String escapedValue;
            String upperOp = op.trim().toUpperCase();
            
            if (value instanceof String) {
                // Escape single quotes for SOQL
                String stringValue = (String) value;
                stringValue = stringValue.replace('\'', '\\\'');
                
                // Check if this is a date literal (should not be quoted)
                if (OpenAIStructuredQuery.isDateLiteral(stringValue)) {
                    escapedValue = stringValue;
                } else {
                    escapedValue = '\'' + stringValue + '\'';
                }
            } else if (value instanceof List<Object>) {
                // Handle IN operator
                List<String> valueStrings = new List<String>();
                for (Object v : (List<Object>) value) {
                    if (v instanceof String) {
                        String stringValue = (String) v;
                        stringValue = stringValue.replace('\'', '\\\'');
                        // Check if this is a date literal (should not be quoted)
                        if (OpenAIStructuredQuery.isDateLiteral(stringValue)) {
                            valueStrings.add(stringValue);
                        } else {
                            valueStrings.add('\'' + stringValue + '\'');
                        }
                    } else {
                        valueStrings.add(String.valueOf(v));
                    }
                }
                escapedValue = '(' + String.join(valueStrings, ', ') + ')';
            } else if (value instanceof Boolean) {
                escapedValue = String.valueOf(value).toLowerCase();
            } else {
                // Numbers, dates, etc.
                escapedValue = String.valueOf(value);
            }
            
            return field + ' ' + upperOp + ' ' + escapedValue;
        }
    }
    
    /**
     * Checks if a string value is a date literal that should not be quoted in SOQL
     * @param value The string value to check
     * @return True if the value is a date literal, false otherwise
     */
    public static Boolean isDateLiteral(String value) {
        if (value == null || value == '') {
            return false;
        }
        
        // Check for standard date literals
        if (value.startsWith('YESTERDAY') || 
            value.startsWith('TODAY') || 
            value.startsWith('TOMORROW') ||
            value.startsWith('LAST_WEEK') || 
            value.startsWith('THIS_WEEK') || 
            value.startsWith('NEXT_WEEK') ||
            value.startsWith('LAST_MONTH') || 
            value.startsWith('THIS_MONTH') || 
            value.startsWith('NEXT_MONTH') ||
            value.startsWith('LAST_90_DAYS') || 
            value.startsWith('NEXT_90_DAYS') ||
            value.startsWith('LAST_N_DAYS:') || 
            value.startsWith('NEXT_N_DAYS:') ||
            value.startsWith('LAST_YEAR') || 
            value.startsWith('THIS_YEAR') || 
            value.startsWith('NEXT_YEAR') ||
            value.startsWith('LAST_12_MONTHS') || 
            value.startsWith('NEXT_12_MONTHS')) {
            return true;
        }
        
        // Check for ISO date formats (YYYY-MM-DD)
        if (Pattern.matches('^\\d{4}-\\d{2}-\\d{2}$', value)) {
            return true;
        }
        
        // Check for ISO datetime formats (YYYY-MM-DDTHH:mm:ss.sssZ)
        if (Pattern.matches('^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d{3})?Z$', value)) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Range specification for numeric fields
     */
    public class QueryRange {
        @AuraEnabled public String field;
        @AuraEnabled public Decimal minValue;
        @AuraEnabled public Decimal maxValue;
        
        /**
         * Converts range to SOQL condition
         */
        public String toCondition() {
            List<String> conditions = new List<String>();
            
            if (minValue != null) {
                conditions.add(field + ' >= ' + minValue);
            }
            if (maxValue != null) {
                conditions.add(field + ' <= ' + maxValue);
            }
            
            return String.join(conditions, ' AND ');
        }
    }
    
    /**
     * Sort specification
     */
    public class SortSpec {
        @AuraEnabled public String field;
        @AuraEnabled public String order_x; // ASC or DESC
    }
}
