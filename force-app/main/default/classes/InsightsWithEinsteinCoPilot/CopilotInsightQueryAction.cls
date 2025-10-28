public with sharing class CopilotInsightQueryAction {
    
    @InvocableMethod(
        label='Query Insights with Natural Language'
        description='Searches for Insight records based on natural language queries. Example: "show me open banking insights from this year"'
        category='Insights'
    )
    public static List<QueryResponse> queryInsights(List<QueryRequest> requests) {
        List<QueryResponse> responses = new List<QueryResponse>();
        
        if (requests == null || requests.isEmpty()) {
            return responses;
        }
        
        QueryRequest request = requests[0];
        QueryResponse response = new QueryResponse();
        
        try {
            System.debug('Processing query: ' + request.userQuery);
            
            // Call your existing OpenAI-based service
            OpenAIStructuredQuery.StructuredQuery structuredQuery = 
                OpenAIInsightsClient.getStructuredQuery(
                    request.userQuery, 
                    'gpt-4o-mini'
                );
            
            // Execute the query
            List<Insight__c> results = InsightQueryService.execute(structuredQuery);
            
            // Build response
            response.success = true;
            response.insights = results;
            response.recordCount = results.size();
            response.generatedQuery = structuredQuery.toSOQL();
            response.message = 'Found ' + results.size() + ' insight(s) matching your query';
            
            System.debug('Query successful: ' + results.size() + ' records returned');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Query failed: ' + e.getMessage());
            response.success = false;
            response.insights = new List<Insight__c>();
            response.recordCount = 0;
            response.message = 'Query failed: ' + e.getMessage();
        }
        
        responses.add(response);
        return responses;
    }
    
    // Input wrapper
    public class QueryRequest {
        @InvocableVariable(
            label='Natural Language Query'
            description='The user\'s query in natural language. Example: "show me all open insights"'
            required=true
        )
        public String userQuery;
        
        @InvocableVariable(
            label='AI Provider'
            description='Choose between OpenAI or Einstein (optional, defaults to OpenAI)'
            required=false
        )
        public String aiProvider;
    }
    
    // Output wrapper
    public class QueryResponse {
        @InvocableVariable(label='Success' description='Whether the query was successful')
        public Boolean success;
        
        @InvocableVariable(label='Insights' description='List of matching Insight records')
        public List<Insight__c> insights;
        
        @InvocableVariable(label='Record Count' description='Number of records found')
        public Integer recordCount;
        
        @InvocableVariable(label='Generated Query' description='The SOQL query that was executed')
        public String generatedQuery;
        
        @InvocableVariable(label='Message' description='Status message')
        public String message;
    }
}