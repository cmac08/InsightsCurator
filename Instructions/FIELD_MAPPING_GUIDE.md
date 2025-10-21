# Insight__c Natural Language Query - Field Mapping Guide

## Available Fields

### Standard Fields
- **Id** - Unique record identifier
- **Name** - Auto-generated insight name
- **CreatedDate** - When the record was created
- **CreatedById** - Who created the record
- **LastModifiedDate** - When last modified
- **LastModifiedById** - Who last modified it
- **OwnerId** - Record owner

### Custom Fields

| Field API Name | Type | Purpose | Example Values |
|---------------|------|---------|----------------|
| **Status__c** | Picklist | Workflow status ONLY | Open, Closed, Deferred, Archived |
| **Likelihood__c** | Picklist | Priority/Confidence level | Very High, High, Medium, Low |
| **Insight_Details__c** | Long Text | Contains business details | "Banking sector opportunity...", "Commercial Cards expansion..." |
| **EDGE_Product_Name__c** | Text | Specific product/solution name | "Product X", "EDGE Core", etc. |
| **Rank__c** | Number | Numeric ranking/importance (decimal) | 1.0, 2.5, 10.0 |
| **Account__c** | Lookup | Related account | Account reference |
| **Estimated_Annual_Revenue__c** | Formula (Text) | Revenue estimate | Calculated value |
| **Estimated_Annual_Revenue_Min__c** | Currency | Minimum revenue | $50,000 |
| **Estimated_Annual_Revenue_Max__c** | Currency | Maximum revenue | $100,000 |
| **Average_Annual_Revenue__c** | Currency | Average revenue | $75,000 |
| **Shortlist__c** | Checkbox | Shortlist flag | true/false |

## Query Pattern Guide

### 1. Workflow Status Queries
**Use:** `Status__c` with exact values

```
"Show me open insights"
→ Status__c = 'Open'

"All closed insights"
→ Status__c = 'Closed'

"Deferred or archived insights"
→ Status__c IN ('Deferred', 'Archived')
```

### 2. Priority/Confidence Queries
**Use:** `Likelihood__c` with picklist values

```
"High priority insights"
→ Likelihood__c = 'High'

"Very high likelihood insights"
→ Likelihood__c = 'Very High'

"High or very high priority"
→ Likelihood__c IN ('High', 'Very High')
```

### 3. Industry/Category/Business Type Queries
**Use:** `EDGE_Product_Name__c` with **LIKE** operator

⚠️ **IMPORTANT:** `Insight_Details__c` is a long text field and **CANNOT be filtered** in SOQL!
Use `EDGE_Product_Name__c` for product/industry/category filtering instead.

```
"Banking insights"
→ EDGE_Product_Name__c LIKE '%Banking%'

"Commercial Cards opportunities"
→ EDGE_Product_Name__c LIKE '%Commercial Cards%'

"Retail sector insights"
→ EDGE_Product_Name__c LIKE '%Retail%'
```

### 4. Product-Specific Queries
**Use:** `EDGE_Product_Name__c` for exact product names

```
"Insights for Product X"
→ EDGE_Product_Name__c = 'Product X'
```

### 5. Ranking/Sorting Queries
**Use:** `Rank__c` for numeric sorting

```
"Top 10 insights by rank"
→ ORDER BY Rank__c ASC LIMIT 10

"Rank better than 5"
→ Rank__c <= 5
```

### 6. Revenue Queries
**Use:** Revenue fields for financial filtering

```
"Insights with revenue over 50000"
→ Estimated_Annual_Revenue_Min__c > 50000
```

## Common Query Examples

### Example 1: Combined Filters
```
"Open banking insights with high priority"

Filters:
- Status__c = 'Open'
- Insight_Details__c LIKE '%Banking%'
- Likelihood__c = 'High'
```

### Example 2: Commercial Cards Focus
```
"Commercial Cards insights that are not closed"

Filters:
- Insight_Details__c LIKE '%Commercial Cards%'
- Status__c != 'Closed'
```

### Example 3: Priority Sorting
```
"Top 20 very high likelihood insights for banking"

Filters:
- Likelihood__c = 'Very High'
- Insight_Details__c LIKE '%Banking%'
Sort: Rank__c ASC
Limit: 20
```

## ⚠️ Common Mistakes to Avoid

### ❌ WRONG
```
Category__c = 'Banking'           // Field does not exist!
Industry__c = 'Financial Services' // Field does not exist!
Priority__c = 'High'              // Field does not exist!
Status__c = 'Banking'             // Wrong field for business category!
```

### ✅ CORRECT
```
Insight_Details__c LIKE '%Banking%'           // For business categories
Likelihood__c = 'High'                        // For priority
Status__c = 'Open'                           // For workflow status
```

## Field Selection Best Practices

Always include these base fields:
- **Id** - Required for record identification
- **Name** - Useful for display
- **Status__c** - Shows workflow state
- **Likelihood__c** - Shows priority

Add contextual fields based on query:
- For business category queries → Include `Insight_Details__c`
- For product queries → Include `EDGE_Product_Name__c`
- For revenue queries → Include appropriate revenue fields
- For ranking → Include `Rank__c`

## Testing Your Schema

Run this in Anonymous Apex to verify your org's fields:

```apex
InsightSchemaDebugger.printAvailableFields();
```

This will show:
- All accessible fields
- Field types and descriptions
- What the AI sees in its prompts
- Validation tests for common fields