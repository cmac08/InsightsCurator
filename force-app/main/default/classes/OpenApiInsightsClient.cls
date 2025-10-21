/**
 * Main client for OpenAI API integration
 * Handles communication with OpenAI Responses API
 */
public with sharing class OpenApiInsightsClient {
    
    private static final String NAMED_CREDENTIAL = 'OpenAI';
    private static final String ENDPOINT = 'callout:' + NAMED_CREDENTIAL + '/v1/responses';
    private static final String DEFAULT_MODEL = 'gpt-4o-mini';
    
    /**
     * Main entry point: Converts natural language to structured Salesforce query
     * @param prompt Natural language query from user
     * @param modelName Optional OpenAI model name
     * @return StructuredQuery object ready for SOQL generation
     */
    @AuraEnabled(cacheable=false)
    public static OpenAIStructuredQuery.StructuredQuery getStructuredQuery(String prompt, String modelName) {
        if (String.isBlank(prompt)) {
            throw new OpenAIException('Prompt cannot be blank.');
        }
        
        String modelToUse = String.isBlank(modelName) ? DEFAULT_MODEL : modelName;
        
        // Build and send request
        OpenAIRequest request = OpenAIRequestBuilder.buildQueryRequest(prompt, modelToUse);
        HttpResponse response = sendRequest(request);
        
        // Parse and validate response
        return OpenAIResponseParser.parseQueryResponse(response);
    }
    
    /**
     * Sends HTTP request to OpenAI API
     */
    private static HttpResponse sendRequest(OpenAIRequest request) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getApiKey());
        req.setBody(JSON.serialize(request));
        
        System.debug('=== OpenAI Request ===');
        System.debug('Endpoint: ' + req.getEndpoint());
        System.debug('Body: ' + req.getBody());
        
        Http http = new Http();
        HttpResponse response;
        
        try {
            response = http.send(req);
        } catch (Exception e) {
            throw new OpenAIException('HTTP callout failed: ' + e.getMessage(), e);
        }
        
        System.debug('=== OpenAI Response ===');
        System.debug('Status: ' + response.getStatusCode());
        System.debug('Body: ' + response.getBody());
        
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throw new OpenAIException(
                'OpenAI API error (' + response.getStatusCode() + '): ' + response.getBody()
            );
        }
        
        return response;
    }
    
    /**
     * Retrieves API key from Custom Metadata
     */
    private static String getApiKey() {
        List<API_Setting__mdt> settings = [
            SELECT ClientSecret__c 
            FROM API_Setting__mdt 
            WHERE DeveloperName = 'OpenAICredential'
            LIMIT 1
        ];
        
        if (settings.isEmpty() || String.isBlank(settings[0].ClientSecret__c)) {
            throw new OpenAIException('OpenAI API key not configured in Custom Metadata');
        }
        
        return settings[0].ClientSecret__c;
    }
    
    public class OpenAIException extends Exception {}
    
    /**
     * Simple DTO for OpenAI request
     */
    public class OpenAIRequest {
        public String model;
        public String instructions;
        public String input;
    }
}