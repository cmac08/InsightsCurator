public with sharing class NLPQueryController {
    private static final String OPENAI_API_KEY = 'CreateNamedCredentail';

    @AuraEnabled(cacheable=true)
    public static Map<String, String> parseQuery(String query) {
        // Example using OpenAI API (you'll need to store your API key securely)
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.openai.com/v1/responses');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', OPENAI_API_KEY);

        String prompt = 'You translate a users natural language into a strict query for SOQL (JSON)';

        request.setBody(JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4',
            'messages' => new List<Object>{
                new Map<String, Object>{ 'role' => 'user', 'content' => prompt }
            }
        }));

        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // String content = (String)((Map<String, Object>)((List<Object>)result.get('choices'))[0]).get('message').get('content');
            String content = ((List<Object>)result.get('choices'))[0].get('message').get('content');


            // Example response: "industry: Manufacturing, productInterest: Credit, timeframe: Last 60 days"
            Map<String, String> filters = new Map<String, String>();
            for (String part : content.split(',')) {
                List<String> kv = part.split(':');
                if (kv.size() == 2) {
                    filters.put(kv[0].trim(), kv[1].trim());
                }
            }
            return filters;
        } else {
            throw new AuraHandledException('Failed to parse query: ' + response.getBody());
        }
    }
}