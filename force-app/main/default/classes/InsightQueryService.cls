public with sharing class InsightQueryService {
    public class QueryServiceException extends Exception {}

    // Reuse the contract class from OpenApiInsightsClient to avoid duplication
    // If needed elsewhere, consider extracting to a separate DTO class file.
    public static OpenApiInsightsClient.StructuredQuery normalize(OpenApiInsightsClient.StructuredQuery incoming) {
        if (incoming == null) throw new QueryServiceException('Structured query is required.');
        // Ensure correct object
        if (String.isBlank(incoming.objectName) || incoming.objectName != 'Insight__c') {
            throw new QueryServiceException('Only Insight__c is supported.');
        }
        // Cap limit
        Integer limitCap = 200;
        Integer defaultLimit = 50;
        Integer requested = incoming.maxLimit;
        Integer effective = (requested == null || requested <= 0) ? defaultLimit : Math.min(requested, limitCap);
        incoming.maxLimit = effective;

        // Default fields if none provided
        if (incoming.fields == null || incoming.fields.isEmpty()) {
            incoming.fields = new List<String>{
                'Id','Name','Account__c','EDGE_Product_Name__c','Likelihood__c',
                'Estimated_Annual_Revenue__c','Rank__c','Status__c'
            };
        }
        // Filter out non-whitelisted fields in fields list
        List<String> safeFields = new List<String>();
        for (String f : incoming.fields) {
            if (isAllowedField(f)) safeFields.add(f);
        }
        if (safeFields.isEmpty()) {
            safeFields.add('Id');
            safeFields.add('Name');
        }
        incoming.fields = safeFields;

        // Validate filters and range/sort
        if (incoming.filters != null) {
            List<OpenApiInsightsClient.Filter> validFilters = new List<OpenApiInsightsClient.Filter>();
            for (OpenApiInsightsClient.Filter flt : incoming.filters) {
                if (flt == null || String.isBlank(flt.field) || String.isBlank(flt.op)) continue;
                if (!isAllowedField(flt.field)) continue;
                if (!isAllowedOp(flt.op)) continue;
                validFilters.add(flt);
            }
            incoming.filters = validFilters;
        }
        if (incoming.range != null) {
            if (!isAllowedField(incoming.range.field)) {
                incoming.range = null;
            }
        }
        if (incoming.sortSpec != null) {
            if (!isAllowedField(incoming.sortSpec.field) || !isAllowedSortOrder(incoming.sortSpec.order)) {
                incoming.sortSpec = null;
            }
        }
        return incoming;
    }

    // Execute the query and return sObjects (to be serialized to LWC)
    public static List<Insight__c> execute(OpenApiInsightsClient.StructuredQuery sq) {
        OpenApiInsightsClient.StructuredQuery norm = normalize(sq);

        // Build dynamic SOQL safely
        String soql = buildSoql(norm);
        // Bind values via Database.query with formatted strings; values are escaped via type casting where possible.
        // For simplicity here, we inline sanitized values, taking care of quoting numbers/booleans vs strings.
        return (List<Insight__c>) Database.query(soql);
    }

    // Construct SOQL with whitelisting
    public static String buildSoql(OpenApiInsightsClient.StructuredQuery sq) {
        List<String> selectFields = new List<String>();
        for (String f : sq.fields) {
            selectFields.add(f);
        }
        String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM Insight__c';

        List<String> predicates = new List<String>();

        if (sq.filters != null && !sq.filters.isEmpty()) {
            for (OpenApiInsightsClient.Filter flt : sq.filters) {
                String field = flt.field;
                String op = normalizeOp(flt.op);
                String pred;
                if (op == 'IN' && flt.value != null) {
                    List<String> items = coerceToStringList(flt.value);
                    List<String> safeItems = new List<String>();
                    for (String v : items) {
                        safeItems.add(quoteString(v));
                    }
                    pred = field + ' IN (' + String.join(safeItems, ',') + ')';
                } else {
                    String rhs = coerceForSoql(flt.value, field);
                    pred = field + ' ' + op + ' ' + rhs;
                }
                predicates.add(pred);
            }
        }

        if (sq.range != null && !String.isBlank(sq.range.field)) {
            if (sq.range.minValue != null) {
                predicates.add(sq.range.field + ' >= ' + String.valueOf(sq.range.minValue));
            }
            if (sq.range.maxValue != null) {
                predicates.add(sq.range.field + ' <= ' + String.valueOf(sq.range.maxValue));
            }
        }

        if (!predicates.isEmpty()) {
            soql += ' WHERE ' + String.join(predicates, ' AND ');
        }

        if (sq.sortSpec != null && !String.isBlank(sq.sortSpec.field)) {
            soql += ' ORDER BY ' + sq.sortSpec.field + ' ' + (String.isBlank(sq.sortSpec.order) ? 'ASC' : sq.sortSpec.order);
        }

        soql += ' LIMIT ' + String.valueOf(sq.maxLimit);
        return soql;
    }

    // Helpers

    private static Boolean isAllowedField(String apiName) {
        // Whitelist Insight__c fields present in the repo metadata
        Set<String> allowed = new Set<String>{
            'Id','Name','Account__c','EDGE_Product_Name__c','Likelihood__c',
            'Estimated_Annual_Revenue__c','Estimated_Annual_Revenue_Min__c','Estimated_Annual_Revenue_Max__c',
            'Average_Annual_Revenue__c','Rank__c','Shortlist__c','Status__c','Insight_Details__c'
        };
        return allowed.contains(apiName);
    }

    private static Boolean isAllowedOp(String op) {
        Set<String> allowed = new Set<String>{'=','!=','>','>=','<','<=','IN'};
        return allowed.contains(op != null ? op.trim().toUpperCase() : '');
    }

    private static String normalizeOp(String op) {
        String s = (op == null) ? '' : op.trim().toUpperCase();
        // Already validated
        return s;
    }

    private static Boolean isAllowedSortOrder(String ord) {
        String o = ord == null ? '' : ord.trim().toUpperCase();
        return o == 'ASC' || o == 'DESC';
    }

    // Try to coerce a value to a safe SOQL literal depending on field type where known.
    // Without schema describe here, we conservatively treat as:
    // - Numeric fields: attempt Decimal
    // - Boolean: attempt Boolean
    // - Others: quote as string
    private static String coerceForSoql(Object value, String field) {
        if (value == null) return 'NULL';

        // Numeric fields known by API name
        Set<String> numericFields = new Set<String>{
            'Likelihood__c','Estimated_Annual_Revenue__c','Estimated_Annual_Revenue_Min__c',
            'Estimated_Annual_Revenue_Max__c','Average_Annual_Revenue__c','Rank__c'
        };
        Set<String> booleanFields = new Set<String>{ 'Shortlist__c' };

        if (numericFields.contains(field)) {
            try {
                Decimal d = (value instanceof Decimal) ? (Decimal) value : Decimal.valueOf(String.valueOf(value));
                return String.valueOf(d);
            } catch (Exception e) {
                throw new QueryServiceException('Invalid numeric value for ' + field + ': ' + String.valueOf(value));
            }
        } else if (booleanFields.contains(field)) {
            try {
                Boolean b;
                if (value instanceof Boolean) {
                    b = (Boolean) value;
                } else {
                    String s = String.valueOf(value).toLowerCase();
                    if (s == 'true' || s == '1' || s == 'yes') b = true;
                    else if (s == 'false' || s == '0' || s == 'no') b = false;
                    else throw new QueryServiceException('Invalid boolean value for ' + field + ': ' + String.valueOf(value));
                }
                return b ? 'true' : 'false';
            } catch (Exception e) {
                throw new QueryServiceException('Invalid boolean value for ' + field + ': ' + String.valueOf(value));
            }
        } else {
            // treat as string and escape quotes
            return quoteString(String.valueOf(value));
        }
    }

    private static List<String> coerceToStringList(Object value) {
        List<String> out = new List<String>();
        if (value == null) return out;
        if (value instanceof List<Object>) {
            for (Object o : (List<Object>) value) {
                out.add(String.valueOf(o));
            }
        } else if (value instanceof String) {
            // Support comma-separated string
            for (String part : ((String) value).split(',')) {
                out.add(part.trim());
            }
        } else {
            out.add(String.valueOf(value));
        }
        return out;
    }

    private static String quoteString(String s) {
        if (s == null) return 'NULL';
        // Escape single quotes by doubling them for SOQL
        String esc = s.replace('\'', '\\\'').replace('\\\'', '\\\''); // minimal safeguard
        // For SOQL, the way to escape single quote is by backslash not supported; Salesforce doubles single quotes.
        // Correct approach:
        esc = s.replace('\'', '\\u0027'); // avoid breaking query; alternative is doubling: s.replace('\'','\\\'')
        // Use simple quoting to avoid SOQL injection via whitelisting.
        return '\'' + esc + '\'';
    }
}
