public with sharing class OpenApiInsightsClient {
    public class OpenAIException extends Exception {}

    // DTO for OpenAI Responses API request
    public class OpenAIRequest {
        public String model;
        public Object input;
        public Object instructions;
        public Object response_format; // can be String or Map, we will allow Object for flexibility
        public OpenAIRequest withModel(String m) { this.model = m; return this; }
        public OpenAIRequest withInput(Object i) { this.input = i; return this; }
        public OpenAIRequest withInstructions(Object i) { this.instructions = i; return this; }
        public OpenAIRequest withResponseFormat(Object rf) { this.response_format = rf; return this; }
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
        public String type; // e.g., 'output_text' or 'output_json'
        public String text; // when type == 'output_text'
        public Object content; // flexible for future use
        public String innerContent; // rename to avoid reserved identifier 'inner' errors in some parsers
    }

    // Contract we expect from the model: a structured JSON for querying Insight__c
    public class StructuredQuery {
        public String objectName; // expected 'Insight__c'
        public List<Filter> filters;
        public Range range;
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
        public String order; // ASC|DESC
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
     *  - model: optional model name (defaults to 'gpt-4.1-mini' or any org-configured default)
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
            + '}.'
            + 'Use Salesforce API field names for Insight__c. If uncertain, omit that part. '
            + 'Set objectName to "Insight__c". Prefer limit ≤ 100.';

        // We request JSON object via response_format
        Map<String, Object> responseFormat = new Map<String, Object>{ 'type' => 'json_object' };

        OpenAIRequest reqBody = new OpenAIRequest()
            .withModel(modelToUse)
            .withInput(new Map<String,Object>{ 'prompt' => prompt })
            .withInstructions(instructions)
            .withResponseFormat(responseFormat);

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(reqBody));

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
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new OpenAIException('OpenAI error ' + res.getStatus() + ': ' + res.getBody());
        }

        // The Responses API may return a list of outputs; we expect json object content.
        // Try to parse the entire body as the JSON object we need. If it includes wrapper, try to extract.
        StructuredQuery sq;
        try {
            // First, try direct parse (assumes pure JSON object)
            sq = (StructuredQuery) System.JSON.deserialize(res.getBody(), StructuredQuery.class);
        } catch (Exception ex1) {
            // Fallback: the Responses API returns a wrapper with output list; try to extract a JSON block
            try {
                OpenAIResponse oar = (OpenAIResponse) System.JSON.deserialize(res.getBody(), OpenAIResponse.class);
                if (oar != null && oar.output != null) {
                    for (ResponseOutput ro : oar.output) {
                        if (ro != null && ro.text != null) {
                            try {
                                sq = (StructuredQuery) System.JSON.deserialize(ro.text, StructuredQuery.class);
                                if (sq != null) break;
                            } catch (Exception exInner) {
                                // continue
                            }
                        }
                    }
                }
            } catch (Exception ex2) {
                // Will error below if sq remains null
            }
        }

        if (sq == null) {
            throw new OpenAIException('Unable to parse structured query from OpenAI response: ' + res.getBody());
        }
        return sq;
    }
}
