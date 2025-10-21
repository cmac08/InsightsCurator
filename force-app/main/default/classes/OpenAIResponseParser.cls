/**
 * Parses OpenAI API responses and extracts structured data
 */
public with sharing class OpenAIResponseParser {
    
    /**
     * Parses OpenAI response and extracts StructuredQuery
     * @param response HTTP response from OpenAI API
     * @return Parsed and validated StructuredQuery
     */
    public static OpenAIStructuredQuery.StructuredQuery parseQueryResponse(HttpResponse response) {
        try {
            // Step 1: Parse the HTTP response body
            String responseBody = response.getBody();
            Map<String, Object> fullResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            System.debug('=== Parsing OpenAI Response ===');
            
            // Step 2: Check for API-level errors
            validateNoErrors(fullResponse);
            
            // Step 3: Extract the text content from nested structure
            String jsonText = extractJsonText(fullResponse);
            System.debug('Extracted JSON text: ' + jsonText);
            
            // Step 4: Clean any potential formatting issues
            jsonText = cleanJsonText(jsonText);
            System.debug('Cleaned JSON text: ' + jsonText);
            
            // Step 5: Parse into StructuredQuery
            OpenAIStructuredQuery.StructuredQuery query = parseStructuredQuery(jsonText);
            
            // Step 6: Validate the query
            validateQuery(query);
            
            System.debug('Successfully parsed query: ' + JSON.serializePretty(query));
            return query;
            
        } catch (OpenApiInsightsClient.OpenAIException e) {
            // Re-throw our custom exceptions
            throw e;
        } catch (JSONException e) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Invalid JSON in OpenAI response: ' + e.getMessage() + 
                '\nResponse: ' + response.getBody(),
                e
            );
        } catch (Exception e) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Unexpected error parsing OpenAI response: ' + e.getMessage() + 
                '\nResponse: ' + response.getBody(),
                e
            );
        }
    }
    
    /**
     * Checks for error field in OpenAI response
     */
    private static void validateNoErrors(Map<String, Object> response) {
        Object errorObj = response.get('error');
        if (errorObj != null) {
            String errorMessage = String.valueOf(errorObj);
            throw new OpenApiInsightsClient.OpenAIException(
                'OpenAI API returned error: ' + errorMessage
            );
        }
    }
    
    /**
     * Navigates nested response structure to extract the JSON text
     * Structure: response.output[0].content[0].text
     */
    private static String extractJsonText(Map<String, Object> response) {
        try {
            // Navigate: output array
            List<Object> outputList = (List<Object>) response.get('output');
            if (outputList == null || outputList.isEmpty()) {
                throw new OpenApiInsightsClient.OpenAIException(
                    'OpenAI response missing "output" array'
                );
            }
            
            // Navigate: first output item
            Map<String, Object> firstOutput = (Map<String, Object>) outputList[0];
            if (firstOutput == null) {
                throw new OpenApiInsightsClient.OpenAIException(
                    'OpenAI response output array is empty'
                );
            }
            
            // Navigate: content array
            List<Object> contentList = (List<Object>) firstOutput.get('content');
            if (contentList == null || contentList.isEmpty()) {
                throw new OpenApiInsightsClient.OpenAIException(
                    'OpenAI response missing "content" array in output'
                );
            }
            
            // Navigate: first content item
            Map<String, Object> firstContent = (Map<String, Object>) contentList[0];
            if (firstContent == null) {
                throw new OpenApiInsightsClient.OpenAIException(
                    'OpenAI response content array is empty'
                );
            }
            
            // Extract: text field
            String text = (String) firstContent.get('text');
            if (String.isBlank(text)) {
                throw new OpenApiInsightsClient.OpenAIException(
                    'OpenAI response text content is empty'
                );
            }
            
            return text;
            
        } catch (TypeException e) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Unexpected structure in OpenAI response: ' + e.getMessage(),
                e
            );
        }
    }
    
    /**
     * Removes markdown code blocks and extra whitespace
     */
    private static String cleanJsonText(String jsonText) {
        if (String.isBlank(jsonText)) {
            return jsonText;
        }
        
        // Remove markdown code blocks (```json and ```)
        jsonText = jsonText.replace('```json', '');
        jsonText = jsonText.replace('```', '');
        
        // Trim whitespace
        jsonText = jsonText.trim();
        
        // Validate it starts with { and ends with }
        if (!jsonText.startsWith('{')) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Invalid JSON: Does not start with {. Got: ' + jsonText.substring(0, Math.min(50, jsonText.length()))
            );
        }
        if (!jsonText.endsWith('}')) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Invalid JSON: Does not end with }. Got: ....' + jsonText.substring(Math.max(0, jsonText.length() - 50))
            );
        }
        
        return jsonText;
    }
    
    /**
     * Parses JSON text into StructuredQuery object
     */
    private static OpenAIStructuredQuery.StructuredQuery parseStructuredQuery(String jsonText) {
        try {
            // Parse as untyped map first to handle reserved keywords
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
            
            // Create and populate StructuredQuery manually
            OpenAIStructuredQuery.StructuredQuery query = new OpenAIStructuredQuery.StructuredQuery();
            
            // Map simple fields
            query.objectName = (String) jsonMap.get('objectName');
            query.limit_x = jsonMap.containsKey('limit') ? 
                (Integer) jsonMap.get('limit') : null;
            
            // Map fields array
            if (jsonMap.containsKey('fields')) {
                List<Object> fieldsList = (List<Object>) jsonMap.get('fields');
                query.fields = new List<String>();
                for (Object field : fieldsList) {
                    query.fields.add((String) field);
                }
            }
            
            // Map filters array
            if (jsonMap.containsKey('filters')) {
                query.filters = parseFilters((List<Object>) jsonMap.get('filters'));
            }
            
            // Map range object
            if (jsonMap.containsKey('range')) {
                query.range_x = parseRange((Map<String, Object>) jsonMap.get('range'));
            }
            
            // Map sort object
            if (jsonMap.containsKey('sort')) {
                query.sort_x = parseSort((Map<String, Object>) jsonMap.get('sort'));
            }
            
            return query;
            
        } catch (Exception e) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Failed to parse JSON into StructuredQuery: ' + e.getMessage() + 
                '\nJSON was: ' + jsonText,
                e
            );
        }
    }
    
    /**
     * Parses filters array from JSON map
     */
    private static List<OpenAIStructuredQuery.Filter> parseFilters(List<Object> filtersList) {
        if (filtersList == null) return null;
        
        List<OpenAIStructuredQuery.Filter> filters = new List<OpenAIStructuredQuery.Filter>();
        
        for (Object filterObj : filtersList) {
            Map<String, Object> filterMap = (Map<String, Object>) filterObj;
            OpenAIStructuredQuery.Filter filter = new OpenAIStructuredQuery.Filter();
            
            filter.field = (String) filterMap.get('field');
            filter.op = (String) filterMap.get('op');
            filter.value = filterMap.get('value');
            
            filters.add(filter);
        }
        
        return filters;
    }
    
    /**
     * Parses range object from JSON map
     */
    private static OpenAIStructuredQuery.QueryRange parseRange(Map<String, Object> rangeMap) {
        if (rangeMap == null) return null;
        
        OpenAIStructuredQuery.QueryRange range = new OpenAIStructuredQuery.QueryRange();
        range.field = (String) rangeMap.get('field');
        
        Object minVal = rangeMap.get('minValue');
        if (minVal != null) {
            range.minValue = minVal instanceof Decimal ? 
                (Decimal) minVal : Decimal.valueOf(String.valueOf(minVal));
        }
        
        Object maxVal = rangeMap.get('maxValue');
        if (maxVal != null) {
            range.maxValue = maxVal instanceof Decimal ? 
                (Decimal) maxVal : Decimal.valueOf(String.valueOf(maxVal));
        }
        
        return range;
    }
    
    /**
     * Parses sort object from JSON map
     */
    private static OpenAIStructuredQuery.SortSpec parseSort(Map<String, Object> sortMap) {
        if (sortMap == null) return null;
        
        OpenAIStructuredQuery.SortSpec sort_x = new OpenAIStructuredQuery.SortSpec();
        sort_x.field = (String) sortMap.get('field');
        
        // Handle both "order" from JSON and map to "order_x" in Apex
        Object orderValue = sortMap.get('order');
        if (orderValue != null) {
            sort_x.order_x = (String) orderValue;
        }
        
        return sort_x;
    }
    
    /**
     * Validates required fields in the query
     */
    private static void validateQuery(OpenAIStructuredQuery.StructuredQuery query) {
        if (query == null) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Parsed query is null'
            );
        }
        
        if (String.isBlank(query.objectName)) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Query missing required field: objectName'
            );
        }
        
        if (query.objectName != 'Insight__c') {
            throw new OpenApiInsightsClient.OpenAIException(
                'Query objectName must be "Insight__c", got: ' + query.objectName
            );
        }
        
        if (query.fields == null || query.fields.isEmpty()) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Query missing required field: fields array'
            );
        }
        
        // Validate Id and Name are included
        Set<String> fieldSet = new Set<String>(query.fields);
        if (!fieldSet.contains('Id')) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Query fields must include "Id"'
            );
        }
        if (!fieldSet.contains('Name')) {
            throw new OpenApiInsightsClient.OpenAIException(
                'Query fields must include "Name"'
            );
        }
    }
}