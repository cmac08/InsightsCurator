# InsightsCurator Business User Guide

## Table of Contents

1. [Welcome](#welcome)
2. [Getting Started](#getting-started)
3. [How to Use Insight Curator](#how-to-use-insight-curator)
4. [Writing Effective Queries](#writing-effective-queries)
5. [Understanding Your Results](#understanding-your-results)
6. [Common Use Cases](#common-use-cases)
7. [Tips and Best Practices](#tips-and-best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Frequently Asked Questions](#frequently-asked-questions)

## Welcome

Insight Curator is a powerful tool that lets you search and analyze your Insights using natural language. Instead of learning complex database queries or clicking through multiple filters, you can simply type what you're looking for in plain English.

### What Can I Do With Insight Curator?

- Find insights by status, priority, or product
- Search by account or time period
- Sort and rank your most important insights
- Quickly identify high-value opportunities
- Export results for presentations or reports

### Who Should Use This Tool?

Insight Curator is designed for:
- Sales teams tracking opportunities
- Account managers reviewing client insights
- Executives needing quick insights overview
- Product managers analyzing solution trends
- Anyone who needs fast access to Insight data

## Getting Started

### Accessing Insight Curator

1. Log into Salesforce
2. Navigate to your Home page or designated Lightning page
3. Locate the **Insight Curator** component
4. You'll see a text box where you can enter your query

### First Time Setup

Your Salesforce administrator needs to configure the tool before you can use it. If you see an error message when first using the tool, contact your administrator to ensure:
- The tool is properly configured
- You have the necessary permissions
- Your organization has an OpenAI API connection set up

## How to Use Insight Curator

### Basic Steps

1. **Type Your Query**: Enter what you're looking for in plain English
2. **Click Search**: Press the "Search" button or hit Enter
3. **Review Results**: Your insights appear in an easy-to-read table
4. **Take Action**: Click on any row to view or edit the insight

### Your First Query

Try this simple query to get started:

```
Show me all open insights
```

Click Search and you'll see all insights with an "Open" status displayed in a table with key information like:
- Insight name
- Related account
- Solution/product
- Status and priority
- Revenue estimates

### Example Queries

Here are some queries you can try:

**Status-Based Queries:**
- "Show me open insights"
- "All closed insights"
- "Deferred insights"

**Priority Queries:**
- "High priority insights"
- "Very high likelihood insights"
- "Show me insights with high or very high priority"

**Product/Solution Queries:**
- "Banking insights"
- "Commercial Cards opportunities"
- "EDGE Core Banking insights"

**Time-Based Queries:**
- "Insights created today"
- "Insights from this year"
- "Insights created in the last 30 days"
- "Insights updated this month"

**Combined Queries:**
- "Open banking insights with high priority"
- "Very high likelihood Commercial Cards insights"
- "Open insights created this year"
- "High priority insights sorted by rank"

**Ranking Queries:**
- "Top 10 insights by rank"
- "Top 20 insights"
- "Insights ranked better than 5"

## Writing Effective Queries

### Query Structure

The best queries are simple and specific. Think about:
1. **What status?** (Open, Closed, Deferred, Archived)
2. **What priority?** (Very High, High, Medium, Low)
3. **What product/solution?** (Banking, Commercial Cards, etc.)
4. **What time period?** (Today, this year, last 30 days)
5. **How should results be sorted?** (By rank, by date)

### Using Keywords

#### Status Keywords
Use these words to filter by workflow status:
- "open" → Shows Open insights
- "closed" → Shows Closed insights
- "deferred" → Shows Deferred insights
- "archived" → Shows Archived insights

#### Priority Keywords
Use these words to filter by priority/confidence:
- "very high priority" or "very high likelihood"
- "high priority" or "high likelihood"
- "medium priority" or "medium likelihood"
- "low priority" or "low likelihood"

#### Product/Solution Keywords
Mention any product name or category:
- "Banking"
- "Commercial Cards"
- "EDGE Core"
- "Retail"
- Any product name from your organization

#### Time Keywords
Use these phrases for date filtering:
- "today"
- "yesterday"
- "this week" / "last week"
- "this month" / "last month"
- "this year" / "last year"
- "last 30 days" or "last 90 days"
- "created today" (for when insight was created)
- "updated today" (for when insight was last modified)

#### Sorting Keywords
Use these to organize results:
- "sorted by rank"
- "top 10" or "top 20"
- "highest ranked"

### Query Examples by Scenario

#### Scenario 1: Weekly Team Meeting
**Goal:** Review this week's new high-priority opportunities

**Query:**
```
Show me high priority insights created this week
```

**What You'll Get:** All insights marked as High or Very High priority that were created in the current week.

#### Scenario 2: Account Planning
**Goal:** Find all banking opportunities for quarterly planning

**Query:**
```
Open banking insights sorted by rank
```

**What You'll Get:** All open banking-related insights, organized by rank (most important first).

#### Scenario 3: Executive Dashboard
**Goal:** Quick snapshot of top opportunities

**Query:**
```
Top 20 very high likelihood insights
```

**What You'll Get:** The 20 highest-ranked insights with Very High likelihood.

#### Scenario 4: Product Review
**Goal:** Analyze Commercial Cards opportunities

**Query:**
```
Commercial Cards insights from this year
```

**What You'll Get:** All Commercial Cards insights created in the current calendar year.

#### Scenario 5: Monthly Review
**Goal:** See what's new this month

**Query:**
```
Insights created this month
```

**What You'll Get:** All insights created in the current month.

## Understanding Your Results

### The Results Table

After running a query, you'll see results in a table with these columns:

#### 1. Insight Name
- Auto-generated unique identifier (e.g., I-0001, I-0002)
- Click to view the full record

#### 2. Account
- The company or organization related to this insight
- Clickable link to view the account record

#### 3. Solution
- The product or service this insight relates to
- Examples: "EDGE Core Banking", "Commercial Cards"

#### 4. Status (Color-Coded)
- **Green**: Open (active opportunity)
- **Gray**: Closed (completed or won)
- **Default**: Deferred (postponed)
- **Gray**: Archived (historical record)

#### 5. Likelihood (Color-Coded)
- **Bold Green**: Very High (highest confidence)
- **Green**: High (strong confidence)
- **Default**: Medium (moderate confidence)
- **Gray**: Low (lower confidence)

#### 6. Rank
- Numeric importance score (lower is better)
- Rank 1.0 is the highest priority
- Use for sorting most important insights

#### 7. Est. Revenue
- Estimated annual revenue range
- Format: $X,XXX - $XX,XXX
- Based on minimum and maximum estimates

#### 8. Details
- Brief description of the insight
- Click row to see full details

#### 9. Actions
- **View**: Open record in read-only mode
- **Edit**: Open record for editing

### Color Coding Guide

The table uses colors to help you quickly identify priorities:

**Status Colors:**
- Green = Active (Open)
- Gray = Inactive (Closed, Archived)
- Default = Neutral (Deferred)

**Likelihood Colors:**
- Bold Green = Highest Priority (Very High)
- Green = High Priority (High)
- Default = Medium Priority
- Gray = Lower Priority (Low)

### Reading the Query Summary

After results load, you'll see:
- **Success message**: "Found X record(s)"
- **Generated Query**: Click to expand and see the database query (technical)
- **Record count**: Total number of insights matching your criteria

## Common Use Cases

### Use Case 1: Preparing for a Customer Meeting

**Scenario:** You have a meeting with a banking customer tomorrow and need to review relevant insights.

**Query:**
```
Open banking insights with high priority
```

**What to Do With Results:**
1. Review the top-ranked insights
2. Check estimated revenue for discussion points
3. Click "View" to see full details
4. Note any recent updates

### Use Case 2: Quarter-End Reporting

**Scenario:** You need to report on this quarter's opportunities.

**Query:**
```
Open insights created in the last 90 days
```

**What to Do With Results:**
1. Export results for your report
2. Filter by likelihood for risk assessment
3. Sum estimated revenue for projections
4. Identify patterns by solution type

### Use Case 3: Portfolio Review

**Scenario:** Monthly review of all opportunities in your portfolio.

**Query:**
```
All open insights sorted by rank
```

**What to Do With Results:**
1. Focus on top-ranked items first
2. Update status for any closed deals
3. Revise priority for changing situations
4. Add notes to Detail section

### Use Case 4: Product Performance Analysis

**Scenario:** Analyzing how Commercial Cards opportunities are performing.

**Query:**
```
Commercial Cards insights from this year
```

**What to Do With Results:**
1. Review win rates (open vs closed)
2. Analyze average revenue estimates
3. Identify common account types
4. Plan targeted campaigns

### Use Case 5: Pipeline Cleanup

**Scenario:** Quarterly cleanup of old or stale insights.

**Query:**
```
Open insights created last year
```

**What to Do With Results:**
1. Review each for current relevance
2. Close won or lost opportunities
3. Defer low-priority items
4. Archive outdated insights

## Tips and Best Practices

### Writing Better Queries

**Do:**
- Keep queries simple and specific
- Use common terms like "open", "high priority", "banking"
- Specify time periods when relevant
- Use "top 10" or similar for focused results

**Don't:**
- Use overly complex language
- Try to search by detailed descriptions (use product names instead)
- Expect results for fields not in the system
- Use technical database terms

### Getting More Accurate Results

1. **Be Specific About Status**
   - Instead of: "insights"
   - Try: "open insights"

2. **Specify Priority Clearly**
   - Instead of: "important insights"
   - Try: "very high likelihood insights"

3. **Name Products Explicitly**
   - Instead of: "card insights"
   - Try: "Commercial Cards insights"

4. **Use Clear Time References**
   - Instead of: "recent insights"
   - Try: "insights from last 30 days"

### Maximizing Efficiency

1. **Save Common Queries**: Keep a list of your frequent queries in a document for quick reference

2. **Use Example Queries**: Click the example query buttons to start with templates

3. **Combine Filters**: Get precise results by combining status, priority, and product
   - Example: "Open high priority banking insights"

4. **Sort Strategically**: Use "sorted by rank" to focus on priorities

5. **Limit Results When Needed**: Use "top 10" or "top 20" for focused reviews

### Team Collaboration

1. **Standard Query Language**: Agree on common terms with your team
2. **Share Effective Queries**: Document queries that work well
3. **Regular Reviews**: Schedule team reviews using consistent queries
4. **Update Promptly**: Keep Status and Likelihood current for accurate queries

## Troubleshooting

### "No Results Found"

**Possible Reasons:**
- No insights match your criteria
- Insights exist but you don't have permission to see them
- Query interpreted differently than intended

**Solutions:**
- Try a broader query (e.g., "all insights" vs "open banking insights")
- Check with your administrator about permissions
- Rephrase your query using different keywords

### "Error Processing Query"

**Possible Reasons:**
- System connectivity issue
- Query contains unsupported terms
- Temporary service interruption

**Solutions:**
- Wait a moment and try again
- Simplify your query
- Contact your administrator if error persists

### Results Don't Match Expectations

**Possible Reasons:**
- Query interpreted differently than intended
- Using field names that don't exist
- Searching in the wrong fields

**Solutions:**
- Review the "Generated Query" section to see how your query was interpreted
- Use product names instead of detailed descriptions
- Try rephrasing with simpler terms
- Use the example queries as templates

### Can't See Certain Insights

**Possible Reasons:**
- Record-level security restrictions
- Field-level permissions
- Insights owned by others (if sharing is restricted)

**Solutions:**
- Check with your administrator about access
- Ensure you have the correct profile/permission set
- Ask the insight owner to share with you

## Frequently Asked Questions

### General Questions

**Q: Can I search by account name?**  
A: Not directly in the current version. The tool searches by status, priority, product/solution, and dates. However, the Account column in results is clickable and filterable.

**Q: How many results can I see at once?**  
A: The system returns up to 200 results per query. If you need to see more, use filters to narrow your search, or contact your administrator about exporting larger datasets.

**Q: Can I export results to Excel?**  
A: The current version displays results in the browser. To export, you can copy the data or ask your administrator about adding export functionality.

**Q: Can I save my queries?**  
A: The current version doesn't save queries automatically. We recommend keeping a document with your frequently used queries for quick reference.

**Q: How current is the data?**  
A: Data is real-time from Salesforce. You'll see the most current information as of when you run the query.

### Query Questions

**Q: Can I search within the Details field?**  
A: No, the Details field cannot be searched directly. Use the Solution/Product field for categorization. If you need specific text search in details, use Salesforce's standard search functionality.

**Q: What's the difference between "status" and "priority"?**  
A: 
- **Status** (Status field) = Workflow state: Open, Closed, Deferred, Archived
- **Priority** (Likelihood field) = Confidence/importance: Very High, High, Medium, Low

**Q: How do I search for multiple products?**  
A: The system supports searching one product at a time in a single query. To see multiple products, run separate queries or ask your administrator about advanced filtering.

**Q: Can I use "OR" conditions?**  
A: For priority/likelihood, you can use phrases like "high or very high priority". For other fields, you'll need to run separate queries.

**Q: What if I spell something wrong?**  
A: The system uses AI to interpret queries, so minor misspellings may work. However, for best results, use correct spelling, especially for product names.

### Results Questions

**Q: Why are some fields blank in my results?**  
A: Fields may be blank if:
- The information hasn't been entered yet
- You don't have permission to see that field
- The field is optional and wasn't filled in

**Q: Can I edit insights directly from the results?**  
A: Yes! Click the action button (⚙) in the Actions column and select "Edit" to open the insight in edit mode.

**Q: What does the Rank number mean?**  
A: Rank is a numeric score where lower numbers indicate higher priority. Rank 1.0 is the highest priority, 2.0 is next, and so on. Your team determines how to assign ranks.

**Q: How is the revenue estimate calculated?**  
A: The estimated revenue shown is a range between the minimum and maximum revenue values entered for each insight. This is for planning purposes only.

### Technical Questions

**Q: Why does it take a few seconds to get results?**  
A: The tool uses AI to interpret your query and translate it into a database search. This processing takes a few seconds but ensures you can use natural language instead of learning complex query syntax.

**Q: Is my data secure?**  
A: Yes. The tool respects all Salesforce security settings, including field-level and record-level security. You can only see data you have permission to access.

**Q: Does using this tool count against any limits?**  
A: The tool uses API calls to OpenAI for query processing. Your organization's Salesforce administrator monitors these limits. Normal usage should not cause issues.

**Q: Can I use this tool on mobile?**  
A: Yes! If your Lightning page is accessible on mobile, you can use Insight Curator from your phone or tablet.

### Getting Help

**Q: Who do I contact if something isn't working?**  
A: Contact your Salesforce administrator or IT help desk. They can troubleshoot access issues, permissions, and configuration problems.

**Q: Where can I learn more about the Insight object?**  
A: Ask your administrator for documentation specific to your organization's Insight configuration, or explore the Insight object in Salesforce Setup.

**Q: Can I request new features?**  
A: Yes! Discuss feature requests with your Salesforce administrator. They can submit enhancement requests through your organization's IT processes.

## Quick Reference Card

### Common Query Patterns

| What You Want | Query Example |
|--------------|---------------|
| All open items | "show me open insights" |
| High priority items | "high priority insights" |
| Specific product | "banking insights" |
| Recent items | "insights from last 30 days" |
| Top opportunities | "top 10 insights by rank" |
| Combined filters | "open high priority banking insights" |
| This year's items | "insights from this year" |

### Status Values
- Open
- Closed
- Deferred
- Archived

### Priority Values
- Very High
- High
- Medium
- Low

### Time Phrases
- today / yesterday
- this week / last week
- this month / last month
- this year / last year
- last 30 days / last 90 days

### Quick Tips
1. Keep queries simple
2. Use specific product names
3. Combine status + priority for best results
4. Click "View" to see full details
5. Use color coding to spot priorities quickly

---

**Need Help?**  
Contact your Salesforce administrator or IT help desk for assistance with Insight Curator.

**Document Version:** 1.0  
**Last Updated:** October 2025