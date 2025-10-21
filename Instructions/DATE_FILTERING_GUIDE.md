# Date Field Handling in Natural Language Queries

## The Problem

Salesforce SOQL requires date/datetime values to be **unquoted** and in specific formats. The AI must understand this to generate valid queries.

## Available Date Fields

| Field | Type | Description |
|-------|------|-------------|
| **CreatedDate** | DateTime | When the insight was created |
| **LastModifiedDate** | DateTime | When the insight was last updated |

## Salesforce Date Literals

Use these literals **without quotes** in SOQL filters:

### Relative Date Literals

| Literal | Description | Example Query |
|---------|-------------|---------------|
| `TODAY` | Current day | "insights created today" |
| `YESTERDAY` | Previous day | "insights from yesterday" |
| `THIS_WEEK` | Current week (Sun-Sat) | "insights this week" |
| `THIS_MONTH` | Current calendar month | "insights this month" |
| `THIS_YEAR` | Current calendar year | "insights from this year" |
| `LAST_WEEK` | Previous week | "insights from last week" |
| `LAST_MONTH` | Previous month | "insights from last month" |
| `LAST_YEAR` | Previous year | "insights from last year" |
| `LAST_N_DAYS:n` | Last N days (e.g., 30) | "insights from last 30 days" |
| `LAST_N_MONTHS:n` | Last N months | "insights from last 3 months" |
| `NEXT_N_DAYS:n` | Next N days | "insights due in next 7 days" |

## Query Examples

### Example 1: Today's Insights
```
User: "Show me insights created today"

Generated Filter:
{"field":"CreatedDate","op":"=","value":"TODAY"}

SOQL:
WHERE CreatedDate = TODAY
```

### Example 2: This Year
```
User: "All insights from this year"

Generated Filter:
{"field":"CreatedDate","op":">=","value":"THIS_YEAR"}

SOQL:
WHERE CreatedDate >= THIS_YEAR
```

### Example 3: Last 30 Days
```
User: "Open banking insights from last 30 days"

Generated Filters:
[
  {"field":"Status__c","op":"=","value":"Open"},
  {"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Banking%"},
  {"field":"CreatedDate","op":">=","value":"LAST_N_DAYS:30"}
]

SOQL:
WHERE Status__c = 'Open' 
AND EDGE_Product_Name__c LIKE '%Banking%'
AND CreatedDate >= LAST_N_DAYS:30
```

### Example 4: Modified This Month
```
User: "Insights updated this month"

Generated Filter:
{"field":"LastModifiedDate","op":">=","value":"THIS_MONTH"}

SOQL:
WHERE LastModifiedDate >= THIS_MONTH
```

## Common Date Query Patterns

| User Query | Date Literal | Operator |
|-----------|--------------|----------|
| "created today" | `TODAY` | `=` |
| "from this year" | `THIS_YEAR` | `>=` |
| "last 30 days" | `LAST_N_DAYS:30` | `>=` |
| "this month" | `THIS_MONTH` | `>=` |
| "before yesterday" | `YESTERDAY` | `<` |
| "after last week" | `LAST_WEEK` | `>` |

## ❌ Common Mistakes

### Wrong: Quoted Date Values
```json
// ❌ This will fail
{"field":"CreatedDate","op":"=","value":"'2024-01-15'"}
{"field":"CreatedDate","op":"=","value":"'TODAY'"}
```

### Correct: Unquoted Literals
```json
// ✅ This works
{"field":"CreatedDate","op":"=","value":"TODAY"}
{"field":"CreatedDate","op":">=","value":"LAST_N_DAYS:30"}
```

## Implementation Details

### In the Filter Class

The `Filter.toCondition()` method detects date fields and handles them specially:

```apex
// Check if field is a date field
if (isDateField(field)) {
    escapedValue = formatDateValue(value);  // No quotes!
} else if (value instanceof String) {
    escapedValue = '\'' + stringValue + '\'';  // Quotes for text
}
```

### Recognized Date Fields

Currently recognized date fields:
- `CreatedDate`
- `LastModifiedDate`
- `SystemModstamp`

## AI Prompt Instructions

The AI is instructed to:

1. **Use date literals for temporal queries**
   - "created today" → `CreatedDate = TODAY`
   - "from this year" → `CreatedDate >= THIS_YEAR`

2. **Never quote date values**
   - ❌ `"value":"'TODAY'"`
   - ✅ `"value":"TODAY"`

3. **Use appropriate operators**
   - `=` for exact dates (TODAY, YESTERDAY)
   - `>=` for "from" or "since" queries
   - `<=` for "before" or "until" queries

4. **Include date fields in result set**
   - Add `CreatedDate` to fields array when filtering by it
   - Helps users see the dates in results

## Testing Date Queries

Try these queries to test date handling:

```
"Show me insights created today"
"Open insights from this year"  
"Banking insights from last 30 days"
"Insights updated this month"
"High priority insights created this week"
```

All should generate valid SOQL with proper date literals!