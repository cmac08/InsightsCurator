/**
 * Lightning Web Component Controller for Natural Language Query Processing
 * Entry point for the LWC component - connects UI to OpenAI and Salesforce query execution
 */
public with sharing class NLPQueryController {
    
    /**
     * Processes a natural language prompt and returns matching Insight__c records
     * @param prompt Natural language query from user (e.g., "show me banking insights")
     * @param modelName Optional OpenAI model name (defaults to gpt-4o-mini)
     * @return List of Insight__c records matching the query
     */
    @AuraEnabled(cacheable=true)
    public static QueryResult processPrompt(String prompt, String modelName) {
        QueryResult result = new QueryResult();
        
        try {
            // Validate input
            validateInput(prompt);
            
            // Step 1: Convert natural language to structured query using OpenAI
            OpenAIStructuredQuery.StructuredQuery structuredQuery = 
                OpenApiInsightsClient.getStructuredQuery(prompt, modelName);
            
            System.debug('=== Structured Query Created ===');
            System.debug(JSON.serializePretty(structuredQuery));
            
            // Step 2: Execute the query against Salesforce
            List<Insight__c> records = InsightQueryService.execute(structuredQuery);
            
            // Step 3: Build successful response
            result.success = true;
            result.records = records;
            result.recordCount = records.size();
            result.query = structuredQuery.toSOQL();
            result.message = 'Successfully retrieved ' + records.size() + ' record(s)';
            
            System.debug('=== Query Successful ===');
            System.debug('Records returned: ' + records.size());
            
            return result;
            
        } catch (OpenApiInsightsClient.OpenAIException ex) {
            // OpenAI-specific errors
            System.debug(LoggingLevel.ERROR, '=== OpenAI Error ===');
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            
            result.success = false;
            result.errorType = 'OpenAI Error';
            result.message = 'Failed to process your query with AI: ' + ex.getMessage();
            throw new AuraHandledException(result.message);
            
        } catch (InsightQueryService.QueryServiceException ex) {
            // Query execution errors
            System.debug(LoggingLevel.ERROR, '=== Query Service Error ===');
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            
            result.success = false;
            result.errorType = 'Query Error';
            result.message = 'Failed to execute query: ' + ex.getMessage();
            throw new AuraHandledException(result.message);
            
        } catch (ValidationException ex) {
            // Input validation errors
            System.debug(LoggingLevel.ERROR, '=== Validation Error ===');
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            
            result.success = false;
            result.errorType = 'Validation Error';
            result.message = ex.getMessage();
            throw new AuraHandledException(result.message);
            
        } catch (Exception ex) {
            // Unexpected errors
            System.debug(LoggingLevel.ERROR, '=== Unexpected Error ===');
            System.debug(LoggingLevel.ERROR, ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            
            result.success = false;
            result.errorType = 'System Error';
            result.message = 'An unexpected error occurred: ' + ex.getMessage();
            throw new AuraHandledException(result.message);
        }
    }
    
    /**
     * Validates user input before processing
     */
    private static void validateInput(String prompt) {
        if (String.isBlank(prompt)) {
            throw new ValidationException('Please enter a query. For example: "show me banking insights"');
        }
        
        if (prompt.length() > 500) {
            throw new ValidationException('Query is too long. Please keep it under 500 characters.');
        }
        
        // Basic security check - prevent SOQL injection attempts
        String lowerPrompt = prompt.toLowerCase();
        List<String> dangerousPatterns = new List<String>{
            'drop table', 'delete from', 'truncate', 'insert into', 'update set'
        };
        
        for (String pattern : dangerousPatterns) {
            if (lowerPrompt.contains(pattern)) {
                throw new ValidationException('Invalid query detected. Please use natural language only.');
            }
        }
    }
    
    /**
     * Returns available OpenAI models for the user to choose from
     * This can be called by the LWC to populate a model selector dropdown
     */
    @AuraEnabled(cacheable=true)
    public static List<ModelOption> getAvailableModels() {
        return new List<ModelOption>{
            new ModelOption('GPT-4o Mini (Fast)', 'gpt-4o-mini', true),
            new ModelOption('GPT-4o Mini 2024-07-18', 'gpt-4o-mini-2024-07-18', false),
            new ModelOption('GPT-4o', 'gpt-4o', false)
        };
    }
    
    /**
     * Returns example queries to help users get started
     * Can be displayed in the LWC as quick action buttons or help text
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getExampleQueries() {
        return new List<String>{
            'Show me all open insights',
            'Banking insights from this year',
            'High priority insights for commercial cards',
            'Recent insights sorted by date',
            'Top 10 insights by priority'
        };
    }
    
    // ============================================
    // DTOs (Data Transfer Objects)
    // ============================================
    
    /**
     * Response wrapper for LWC consumption
     */
    public class QueryResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public List<Insight__c> records;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public String query;
        @AuraEnabled public String message;
        @AuraEnabled public String errorType;
        
        public QueryResult() {
            this.success = false;
            this.records = new List<Insight__c>();
            this.recordCount = 0;
            this.query = '';
            this.message = '';
            this.errorType = '';
        }
    }
    
    /**
     * Model option for dropdown selection
     */
    public class ModelOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isDefault;
        
        public ModelOption(String label, String value, Boolean isDefault) {
            this.label = label;
            this.value = value;
            this.isDefault = isDefault;
        }
    }
    
    /**
     * Custom exception for input validation
     */
    public class ValidationException extends Exception {}
}