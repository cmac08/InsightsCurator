public with sharing class OpenApiInsightsClient {
    public class OpenAIException extends Exception {}

    // DTO for OpenAI Responses API request
    public class OpenAIRequest {
        public String model;
        public String instructions;
        public Object input; // Can be String or List<InputMessage>
        
        public OpenAIRequest withModel(String m) { this.model = m; return this; }
        public OpenAIRequest withInstructions(String i) { this.instructions = i; return this; }
        public OpenAIRequest withInput(Object i) { this.input = i; return this; }
    }


    // Minimal DTO for OpenAI Responses API response
    public class OpenAIResponse {
        public String id;
        public String model;
        public String status;
        public List<ResponseOutput> output;
    }
    
    public class ResponseOutput {
        public String id;
        public String type_x; // e.g., 'message'
        public String role;
        public List<OutputContent> content;
    }
    
    public class OutputContent {
        public String type_x; // e.g., 'text'
        public String text;
    }

    // Contract we expect from the model: a structured JSON for querying Insight__c
    public class StructuredQuery {
        public String objectName; // expected 'Insight__c'
        public List<Filter> filters;
        public Range range_x;
        public SortSpec sortSpec;
        public Integer maxLimit;
        public List<String> fields;
    }
    
    public class Filter {
        public String field;
        public String op;   // =, !=, >, >=, <, <=, IN
        public Object value;
    }
    
    public class Range {
        public String field;
        public Decimal minValue;
        public Decimal maxValue;
    }
    
    public class SortSpec {
        public String field;
        public String order_x; // ASC|DESC
    }

    // Named Credential API name provided by user
    private static final String NAMED_CREDENTIAL = 'OpenAI';
    // Full path indicated by user: https://api.openai.com/v1/responses
    private static final String ENDPOINT = 'callout:' + NAMED_CREDENTIAL + '/v1/responses';

    /**
     * Calls OpenAI Responses API with a natural language prompt and asks for a structured JSON
     * suitable to query Insight__c. The LLM should return strictly the JSON object matching
     * StructuredQuery shape.
     *
     * Parameters:
     *  - prompt: end-user natural language text
     *  - modelName: optional model name (defaults to 'gpt-4o-mini')
     */
    @AuraEnabled(cacheable=false)
    public static StructuredQuery getStructuredQuery(String prompt, String modelName) {
        if (String.isBlank(prompt)) {
            throw new OpenAIException('Prompt cannot be blank.');
        }
        String modelToUse = String.isBlank(modelName) ? 'gpt-4o-mini' : modelName;

        // Build strict instruction for JSON output
        String instructions = 'You are a translator that converts a natural language request into a strict JSON spec to query Salesforce object Insight__c. '
            + 'Output ONLY valid JSON matching this schema: '
            + '{'
            + '  "objectName": "Insight__c",'
            + '  "filters": [{"field": "FieldApiName","op": "=|!=|>|>=|<|<=|IN","value": any}],'
            + '  "range": {"field":"NumericFieldApiName","minValue":number,"maxValue":number},'
            + '  "sort": {"field":"FieldApiName","order":"ASC|DESC"},'
            + '  "limit": number,'
            + '  "fields": ["Id","Name", "..."]'
            + '}. '
            + 'Use Salesforce API field names for Insight__c. If uncertain, omit that part. '
            + 'Set objectName to "Insight__c". Prefer limit ≤ 100. '
            + 'Return ONLY the JSON object, no markdown formatting, no explanation.';

        // Build request according to Responses API spec
        // Use simple string input with instructions for structured JSON output
        OpenAIRequest reqBody = new OpenAIRequest()
            .withModel(modelToUse)
            .withInstructions(instructions)
            .withInput(prompt);

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getApiKey());
        
        // Serialize with field name replacements for reserved keywords
        String requestBody = JSON.serialize(reqBody);
        requestBody = requestBody.replace('"type_x":', '"type":');
        requestBody = requestBody.replace('"range_x":', '"range":');
        requestBody = requestBody.replace('"order_x":', '"order":');
        req.setBody(requestBody);

        System.debug('Endpoint: ' + req.getEndpoint());
        System.debug('Method: ' + req.getMethod());
        System.debug('Body: ' + req.getBody());
        
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (Exception e) {
            throw new OpenAIException('Callout failed: ' + e.getMessage());
        }

        if (res == null) {
            throw new OpenAIException('No response from OpenAI.');
        }
        
        System.debug('Response Status: ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());
        
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new OpenAIException('OpenAI error ' + res.getStatus() + ': ' + res.getBody());
        }

        // Parse the Responses API response
        StructuredQuery sq;
        try {
            // Replace type back for deserialization
            String responseBody = res.getBody();
            responseBody = responseBody.replace('"type":', '"type_x":');
            responseBody = responseBody.replace('"range":', '"range_x":');
            responseBody = responseBody.replace('"order":', '"order_x":');
            
            OpenAIResponse oar = (OpenAIResponse) JSON.deserialize(responseBody, OpenAIResponse.class);
            
            if (oar != null && oar.output != null) {
                for (ResponseOutput ro : oar.output) {
                    if (ro != null && ro.content != null) {
                        for (OutputContent oc : ro.content) {
                            if (oc != null && oc.text != null) {
                                try {
                                    // Clean up any markdown formatting
                                    String jsonText = oc.text.trim();
                                    jsonText = jsonText.replace('```json', '').replace('```', '').trim();
                                    
                                    // Replace keywords back for StructuredQuery deserialization
                                    jsonText = jsonText.replace('"range":', '"range_x":');
                                    jsonText = jsonText.replace('"order":', '"order_x":');
                                    
                                    sq = (StructuredQuery) JSON.deserialize(jsonText, StructuredQuery.class);
                                    if (sq != null) break;
                                } catch (Exception exInner) {
                                    System.debug('Error parsing output text: ' + exInner.getMessage());
                                    continue;
                                }
                            }
                        }
                        if (sq != null) break;
                    }
                }
            }
        } catch (Exception ex) {
            throw new OpenAIException('Unable to parse OpenAI response: ' + ex.getMessage() + ' | Response: ' + res.getBody());
        }

        if (sq == null) {
            throw new OpenAIException('Unable to extract structured query from OpenAI response: ' + res.getBody());
        }
        
        return sq;
    }
    public static String getApiKey() {
        //call custom metadata to get the api key
        List<API_Setting__mdt> openAI = [SELECT DeveloperName, ClientSecret__c FROM API_Setting__mdt WHERE DeveloperName = 'OpenAICredential'];
        return openAI[0].ClientSecret__c;

    }
}