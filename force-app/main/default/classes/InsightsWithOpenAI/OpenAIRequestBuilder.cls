/**
 * Builds OpenAI API requests with proper instructions and formatting
 */
public with sharing class OpenAIRequestBuilder {
    
    /**
     * Builds a request to convert natural language to structured query
     */
    public static OpenAIInsightsClient.OpenAIRequest buildQueryRequest(String prompt, String model) {
        OpenAIInsightsClient.OpenAIRequest request = new OpenAIInsightsClient.OpenAIRequest();
        request.model = model;
        request.instructions = getQueryInstructions();
        request.input = prompt;
        return request;
    }
    
    /**
     * Returns optimized instructions for structured query generation
     */
    private static String getQueryInstructions() {
        return 'Convert natural language to JSON query for Salesforce Insight__c object.\n\n'
            + 'CRITICAL: You MUST ONLY use fields from the exact list provided below. DO NOT invent or guess field names.\n\n'
            + 'CRITICAL OUTPUT RULES:\n'
            + '1. Output MUST be raw JSON only - no markdown, no code blocks, no backticks\n'
            + '2. Do NOT wrap output in ```json or ``` tags\n'
            + '3. Do NOT include any text before or after the JSON\n'
            + '4. First character must be { and last character must be }\n'
            + '5. Use standard JSON formatting with proper escaping\n\n'
            + 'JSON SCHEMA:\n'
            + '{\n'
            + '  "objectName": "Insight__c",\n'
            + '  "filters": [\n'
            + '    {"field": "Field__c", "op": "=", "value": "text"}\n'
            + '  ],\n'
            + '  "range": {"field": "Number__c", "minValue": 0, "maxValue": 100},\n'
            + '  "sort": {"field": "Field__c", "order": "ASC"},\n'
            + '  "limit": 100,\n'
            + '  "fields": ["Id", "Name", "Field__c"]\n'
            + '}\n\n'
            + InsightFieldSchema.getFieldDescriptions() + '\n\n'
            + 'FIELD USAGE RULES:\n'
            + '- objectName: Always "Insight__c"\n'
            + '- filters: Array. Operators: =, !=, >, >=, <, <=, IN, LIKE (for text search)\n'
            + '- range: Optional. Use ONLY for numeric fields (Rank__c, revenue fields)\n'
            + '- sort: Optional. Order: "ASC" or "DESC"\n'
            + '- limit: Default 100, max 2000\n'
            + '- fields: MUST ALWAYS include ["Id","Name","Account__c","Account__r.Name","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"] plus any other mentioned fields\n'
            + '- IMPORTANT: When the user provides a person or company name (proper noun) with no explicit field, TREAT IT AS Account__r.Name and use LIKE with wildcards. Example: {"field":"Account__r.Name","op":"LIKE","value":"%Andy Peterson%"}\n'
            + '- DO NOT compare names to Account__c (it is a lookup Id). Only compare Account__c to actual Salesforce Id values when an Id is explicitly provided.\n\n'
            + 'DATE FIELD RULES:\n'
            + '- For date fields (CreatedDate, LastModifiedDate), use Salesforce date literals WITHOUT quotes\n'
            + '- Common literals: YESTERDAY, TODAY, TOMORROW, THIS_WEEK, THIS_MONTH, THIS_YEAR, LAST_90_DAYS\n'
            + '- Parametrized literals: LAST_N_DAYS:n, NEXT_N_DAYS:n, N_DAYS_AGO:n (where n is a number)\n'
            + '- IMPORTANT: LAST_N_DAYS:n includes today (e.g., LAST_N_DAYS:1 = yesterday + today)\n'
            + '- Example date filters:\n'
            + '  → "created today": {"field":"CreatedDate","op":"=","value":"TODAY"}\n'
            + '  → "from this year": {"field":"CreatedDate","op":">=","value":"THIS_YEAR"}\n'
            + '  → "last 30 days": {"field":"CreatedDate","op":">=","value":"LAST_N_DAYS:30"}\n'
            + '  → "exactly 7 days ago": {"field":"CreatedDate","op":"=","value":"N_DAYS_AGO:7"}\n'
            + '  → "last 90 days": {"field":"CreatedDate","op":">=","value":"LAST_90_DAYS"}\n\n'
            + 'COMMON QUERY PATTERNS:\n'
            + '1. Workflow Status: Status__c = "Open" | "Closed" | "Deferred" | "Archived"\n'
            + '2. Priority/Confidence: Likelihood__c = "Very High" | "High" | "Medium" | "Low"\n'
            + '3. Product/Solution/Industry: EDGE_Product_Name__c LIKE "%Commercial Card%" | "%Banking%"\n'
            + '4. Importance: Sort by Rank__c or filter Rank__c >= X\n'
            + '5. Details field: Insight_Details__c can ONLY be in fields array, NEVER in filters\n\n'
            + 'FIELD MISTAKES TO AVOID:\n'
            + '- DO NOT use Category__c (does not exist)\n'
            + '- DO NOT use Industry__c (does not exist)\n'
            + '- DO NOT use Priority__c (does not exist - use Likelihood__c for priority)\n'
            + '- DO NOT use Type__c (does not exist)\n'
            + '- DO NOT filter on Insight_Details__c (long text fields cannot be filtered in SOQL)\n'
            + '- Status__c is ONLY for workflow status (Open/Closed/etc), NOT for business categories\n'
            + '- For business categories like "Banking" or "Commercial Cards", use EDGE_Product_Name__c with LIKE\n\n'
            + 'EXAMPLES:\n\n'
            + 'Input: "insights for Andy Peterson"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"Account__r.Name","op":"LIKE","value":"%Andy Peterson%"}],"limit":100,"fields":["Id","Name","Account__c","Account__r.Name","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "show open insights"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"Status__c","op":"=","value":"Open"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "banking insights"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Banking%"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "high priority commercial cards insights"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"Likelihood__c","op":"IN","value":["High","Very High"]},{"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Commercial Cards%"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "open insights with very high likelihood"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"Status__c","op":"=","value":"Open"},{"field":"Likelihood__c","op":"=","value":"Very High"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "top 10 insights sorted by rank"\n'
            + 'Output: {"objectName":"Insight__c","sort":{"field":"Rank__c","order":"ASC"},"limit":10,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c"]}\n\n'
            + 'Input: "insights created this year"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"CreatedDate","op":">=","value":"THIS_YEAR"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c","CreatedDate"]}\n\n'
            + 'Input: "open banking insights from last 30 days"\n'
            + 'Output: {"objectName":"Insight__c","filters":[{"field":"Status__c","op":"=","value":"Open"},{"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Banking%"},{"field":"CreatedDate","op":">=","value":"LAST_N_DAYS:30"}],"limit":100,"fields":["Id","Name","Account__c","EDGE_Product_Name__c","Status__c","Likelihood__c","Rank__c","Estimated_Annual_Revenue__c","CreatedDate"]}\n\n'
            + 'Convert the user query below. Remember: Use EDGE_Product_Name__c for product/industry filters. NEVER filter on Insight_Details__c. Use date literals (not quoted strings) for date fields. Output only valid JSON.';
    }
}
