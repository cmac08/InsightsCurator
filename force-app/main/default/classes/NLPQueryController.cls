public with sharing class NLPQueryController {
    public class ControllerHandledException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static List<Insight__c> processPrompt(String prompt, String modelName) {
        try {
            // 1) Get structured query from OpenAI via Named Credential 'OpenApi'
            OpenApiInsightsClient.StructuredQuery sq = OpenApiInsightsClient.getStructuredQuery(prompt, modelName);

            // 2) Execute normalized/secure SOQL against Insight__c
            return InsightQueryService.execute(sq);
        } catch (OpenApiInsightsClient.OpenAIException ex1) {
            throw new AuraHandledException('OpenAPI error: ' + ex1.getMessage());
        } catch (InsightQueryService.QueryServiceException ex2) {
            throw new AuraHandledException('Query error: ' + ex2.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }
    }
}
