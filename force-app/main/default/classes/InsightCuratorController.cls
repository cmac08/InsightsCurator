public with sharing class InsightQueryController {
    @AuraEnabled(cacheable=true)
    public static List<Insight__c> getInsights(String industry, String productInterest, Integer daysBack) {
        // Calculate date range
        Date startDate = Date.today().addDays(-daysBack);

        // Query Insights based on filters
        List<Insight__c> insights = [
            SELECT Id, Name, Summary__c, Account__r.Name, Product_Category__c, CreatedDate
            FROM Insight__c
            WHERE Account__r.Industry = :industry
            AND Product_Category__c = :productInterest
            AND CreatedDate >= :startDate
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        return insights;
    }
}