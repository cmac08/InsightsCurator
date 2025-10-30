# InsightsCurator Developer Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Setup and Installation](#setup-and-installation)
5. [Component Reference](#component-reference)
6. [Data Model](#data-model)
7. [API Integration](#api-integration)
8. [Query Processing Flow](#query-processing-flow)
9. [Testing](#testing)
10. [Deployment](#deployment)
11. [Troubleshooting](#troubleshooting)
12. [Maintenance and Extension](#maintenance-and-extension)

## Overview

InsightsCurator is a Salesforce Lightning application that enables natural language querying of Insight__c records using OpenAI's GPT models. The system translates user queries in plain English into structured SOQL queries, executes them securely, and displays results in a responsive data table.

### Key Features

- Natural language to SOQL conversion via OpenAI Responses API
- Dynamic field schema discovery using Salesforce Schema API
- Secure query execution with field-level security
- Fixed column layout for consistent UX
- Date literal support (TODAY, THIS_YEAR, LAST_N_DAYS:n)
- Color-coded Status and Likelihood fields
- Row-level actions (view/edit)
- Support for multiple OpenAI models (GPT-4o-mini, GPT-4o)

### System Requirements

- Salesforce API Version: 60.0+
- OpenAI API access (API key required)
- Lightning Experience enabled
- Required permissions: Named Credentials, External Credentials, Custom Metadata

## Architecture

### High-Level Architecture

```
┌────────────────────┐
│  Lightning Web     │
│   Component (LWC)  │
│  insightCurator    │
└──────────┬─────────┘
           │
           ▼
┌──────────────────────┐
│ NLPQueryController   │
│   (Apex Controller)  │
└──────────┬───────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌───────────────┐  ┌────────────────────┐
│ OpenApiInsights│  │ InsightQueryService│
│     Client     │  │                    │
└────────┬───────┘  └─────────┬──────────┘
         │                    │
         ▼                    ▼
   ┌──────────┐         ┌──────────┐
   │  OpenAI  │         │Salesforce│
   │Responses │         │   SOQL   │
   │   API    │         │  Engine  │
   └──────────┘         └──────────┘
```

### Component Responsibilities

#### Frontend Layer
- **insightCurator (LWC)**: User interface, input validation, result display, error handling

#### Controller Layer
- **NLPQueryController**: Entry point, input validation, exception handling, result aggregation

#### Service Layer
- **OpenApiInsightsClient**: OpenAI API communication, credential management
- **OpenAIRequestBuilder**: Prompt construction with field schemas and examples
- **OpenAIResponseParser**: JSON extraction, validation, error handling
- **InsightQueryService**: Query normalization, security enforcement, SOQL execution
- **InsightFieldSchema**: Dynamic field discovery, metadata caching

#### Data Layer
- **OpenAIStructuredQuery**: DTOs for structured query representation
- **Insight__c**: Custom Salesforce object

### Data Flow

1. User enters natural language query
2. NLPQueryController validates input
3. OpenApiInsightsClient constructs request with field schema
4. OpenAI API returns structured JSON query
5. OpenAIResponseParser validates and extracts query
6. InsightQueryService normalizes fields and enforces security
7. SOQL query executes with field-level security
8. Results enriched with CSS classes for color coding
9. LWC displays in fixed column table

## Technology Stack

### Frontend
- **Lightning Web Components (LWC)**
- **Lightning Data Service**
- **SLDS (Salesforce Lightning Design System)**

### Backend
- **Apex** (API Version 60.0+)
- **SOQL** (Salesforce Object Query Language)
- **Salesforce Schema API** for dynamic field discovery

### Integration
- **OpenAI Responses API** (GPT-4o-mini default, GPT-4o available)
- **Named Credentials** for endpoint configuration
- **External Credentials** for secure API key storage
- **Custom Metadata Types** (API_Setting__mdt)

### Security
- **Field-level security** enforcement
- **Row-level security** via sharing rules
- **SOQL injection** prevention
- **Input validation** and sanitization

## Setup and Installation

### Prerequisites

1. **Salesforce CLI** installed
2. **OpenAI API Key** (obtain from https://platform.openai.com)
3. **Git** for repository access
4. **Dev Hub** enabled org or scratch org/sandbox access
5. **Required Salesforce Permissions**: Manage Named Credentials, Modify All Data

### Installation Steps

#### Step 1: Clone Repository

```bash
git clone https://github.com/cmac08/InsightsCurator.git
cd InsightsCurator
```

#### Step 2: Authorize Salesforce Org

```bash
# For scratch org
sf org create scratch -f config/project-scratch-def.json -a InsightsCurator

# For sandbox
sf org login web -a MySandbox

# For production (use with caution)
sf org login web -a MyProduction
```

#### Step 3: Deploy Metadata

```bash
# Deploy all metadata
sf project deploy start --target-org <org-alias>

# Or deploy specific manifest
sf project deploy start --manifest force-app/main/default/manifest/package.xml --target-org <org-alias>
```

#### Step 4: Configure External Credential

**Manual configuration required** (cannot be automated due to security):

1. Navigate to **Setup** → **Security** → **Named Credentials**
2. Locate "OpenAI" Named Credential
3. Verify configuration:
   - Label: `OpenAI`
   - URL: `https://api.openai.com`
   - Enabled: `true`
   - External Credential: `OpenAI`

4. Navigate to **Setup** → **Security** → **External Credentials**
5. Locate "OpenAI" External Credential
6. Click **Manage Secrets** → **New Principal**
7. Configure principal:
   - Principal Name: `OpenAIPrincipal`
   - Parameter: `ApiKey`
   - Authentication Protocol: `Custom`
   - Value: Your OpenAI API key (begins with `sk-`)

#### Step 5: Verify Custom Metadata

Navigate to **Setup** → **Custom Metadata Types** → **API Setting**

Verify record exists:
- Label: `OpenAICredential`
- DeveloperName: `OpenAICredential`
- ClientSecret__c: (Should reference External Credential)

#### Step 6: Test Configuration

Execute in **Developer Console** → **Debug** → **Open Execute Anonymous Window**:

```apex
// Test OpenAI connection
try {
    OpenAIStructuredQuery.StructuredQuery testQuery = 
        OpenApiInsightsClient.getStructuredQuery('show me all insights', 'gpt-4o-mini');
    System.debug('Connection successful: ' + testQuery);
} catch (Exception e) {
    System.debug('Connection failed: ' + e.getMessage());
}
```

#### Step 7: Add Component to Lightning Page

1. Navigate to **App Builder**
2. Edit Home page or create new page
3. Add **Insight Curator** component
4. Save and activate

#### Step 8: Create Sample Data (Optional)

```apex
List<Insight__c> insights = new List<Insight__c>();

Account testAccount = new Account(Name = 'Test Account');
insert testAccount;

insights.add(new Insight__c(
    Account__c = testAccount.Id,
    EDGE_Product_Name__c = 'EDGE Core Banking',
    Status__c = 'Open',
    Likelihood__c = 'Very High',
    Rank__c = 1.0,
    Estimated_Annual_Revenue_Min__c = 50000,
    Estimated_Annual_Revenue_Max__c = 100000,
    Insight_Details__c = 'Banking sector opportunity for commercial lending expansion'
));

insights.add(new Insight__c(
    Account__c = testAccount.Id,
    EDGE_Product_Name__c = 'Commercial Cards',
    Status__c = 'Open',
    Likelihood__c = 'High',
    Rank__c = 2.5,
    Estimated_Annual_Revenue_Min__c = 75000,
    Estimated_Annual_Revenue_Max__c = 150000,
    Insight_Details__c = 'Commercial card program implementation'
));

insert insights;
```

## Component Reference

### Apex Classes

#### NLPQueryController
Entry point for LWC, orchestrates query processing.

**Methods:**
- `processPrompt(String prompt, String modelName)`: Main query processor
- `validateInput(String prompt)`: Input validation and security
- `getAvailableModels()`: Returns OpenAI model options
- `getExampleQueries()`: Returns sample queries

**Return Type:**
```apex
public class QueryResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public List<Insight__c> records;
    @AuraEnabled public Integer recordCount;
    @AuraEnabled public String query;
    @AuraEnabled public String message;
    @AuraEnabled public String errorType;
}
```

#### OpenApiInsightsClient
Manages OpenAI API communication.

**Methods:**
- `getStructuredQuery(String prompt, String modelName)`: Sends request to OpenAI
- `sendRequest(OpenAIRequest request)`: HTTP callout handler
- `getApiKey()`: Retrieves API key from Custom Metadata

**Configuration:**
- Endpoint: `callout:OpenAI/v1/responses`
- Default Model: `gpt-4o-mini`
- Timeout: Default (120 seconds)

#### OpenAIRequestBuilder
Constructs OpenAI API requests with comprehensive prompts.

**Methods:**
- `buildQueryRequest(String prompt, String model)`: Creates complete request
- `getQueryInstructions()`: Builds instruction prompt with field schemas

**Prompt Structure:**
1. Output format rules (JSON only, no markdown)
2. JSON schema definition
3. Available fields from InsightFieldSchema
4. Field mapping guidance
5. Common query patterns
6. Date literal instructions
7. Example queries with expected output

#### OpenAIResponseParser
Parses and validates OpenAI API responses.

**Methods:**
- `parseQueryResponse(HttpResponse response)`: Main parsing method
- `validateNoErrors(Map<String, Object> response)`: Error detection
- `extractJsonText(Map<String, Object> response)`: JSON extraction from nested structure
- `cleanJsonText(String jsonText)`: Removes markdown formatting
- `parseStructuredQuery(String jsonText)`: Converts to StructuredQuery object
- `validateQuery(StructuredQuery query)`: Validates required fields

#### InsightQueryService
Normalizes and executes secure SOQL queries.

**Methods:**
- `execute(StructuredQuery query)`: Main execution method
- `normalize(StructuredQuery query)`: Security and validation
- `normalizeLimit(Integer limit)`: Caps at 200 records
- `normalizeFields(List<String> fields)`: Ensures essential fields included
- `normalizeFilters(List<Filter> filters)`: Validates and sanitizes
- `isFilterableField(String fieldName)`: Checks if field can be in WHERE clause

**Security Constraints:**
- Max limit: 200 records
- Default limit: 50 records
- Field whitelist enforcement
- Long text fields excluded from filters
- Operator whitelist: =, !=, >, >=, <, <=, IN, NOT IN, LIKE

#### InsightFieldSchema
Dynamic field discovery using Salesforce Schema API.

**Methods:**
- `getAllowedFields()`: Returns all accessible fields
- `getDefaultFields()`: Essential fields for UI
- `getFieldDescriptions()`: Generates AI prompt field list
- `getNumericFields()`: Fields for range queries
- `getBooleanFields()`: Checkbox fields
- `isValidField(String fieldName)`: Field existence check

**Caching:**
- Field map cached in static variable
- Reduces describe calls
- Resets per transaction

### Lightning Web Component

#### insightCurator

**Files:**
- `insightCurator.js`: Component logic
- `insightCurator.html`: Template
- `insightCurator.js-meta.xml`: Configuration
- `insightCurator.css`: Styles (optional)

**Properties:**
```javascript
@track prompt = '';
@track selectedModel = 'gpt-4o-mini';
@track loading = false;
@track results = [];
@track recordCount = 0;
@track generatedQuery = '';
```

**Methods:**
- `handleSubmit()`: Processes query
- `enrichResults(records)`: Adds CSS classes
- `handleRowAction(event)`: Row action handler
- `loadModels()`: Loads available models
- `loadExamples()`: Loads example queries

**Columns (Fixed):**
1. Insight Name (Name)
2. Account (Account__r.Name with URL)
3. Solution (EDGE_Product_Name__c)
4. Status (Status__c) - Color coded
5. Likelihood (Likelihood__c) - Color coded
6. Rank (Rank__c)
7. Est. Revenue (Estimated_Annual_Revenue__c)
8. Details (Insight_Details__c)
9. Actions (View/Edit)

## Data Model

### Insight__c Object

**Standard Fields:**
- Id: Unique identifier
- Name: Auto-number (I-{0000})
- CreatedDate: Record creation timestamp
- LastModifiedDate: Last modification timestamp
- OwnerId: Record owner

**Custom Fields:**

| Field API Name | Type | Description | Values/Format |
|---------------|------|-------------|---------------|
| Account__c | Lookup(Account) | Related account | Account reference |
| EDGE_Product_Name__c | Text(255) | Product/solution name | Free text |
| Status__c | Picklist | Workflow status | Open, Closed, Deferred, Archived |
| Likelihood__c | Picklist | Priority/confidence | Very High, High, Medium, Low |
| Rank__c | Number(4,1) | Importance ranking | Decimal (1.0-9999.0) |
| Estimated_Annual_Revenue_Min__c | Currency(18,2) | Min revenue estimate | Currency |
| Estimated_Annual_Revenue_Max__c | Currency(18,2) | Max revenue estimate | Currency |
| Average_Annual_Revenue__c | Currency(18,2) | Average revenue | Currency |
| Estimated_Annual_Revenue__c | Formula(Text) | Display format | $X,XXX - $X,XXX |
| Insight_Details__c | Long Text Area(32768) | Detailed description | Long text (cannot filter) |
| Shortlist__c | Checkbox | Shortlist flag | true/false |

**Field Usage Notes:**
- `Status__c`: Workflow state only, not for business categories
- `Likelihood__c`: Use for priority/confidence queries
- `EDGE_Product_Name__c`: Use for product/industry/category filters with LIKE
- `Insight_Details__c`: Long text field, cannot be used in WHERE clauses
- `Estimated_Annual_Revenue__c`: Formula field, read-only

## API Integration

### OpenAI Responses API

**Endpoint:**
```
POST https://api.openai.com/v1/responses
```

**Authentication:**
```
Authorization: Bearer {API_KEY}
```

**Request Structure:**
```json
{
  "model": "gpt-4o-mini",
  "instructions": "<comprehensive prompt with field schemas>",
  "input": "<user natural language query>"
}
```

**Response Structure:**
```json
{
  "output": [
    {
      "content": [
        {
          "text": "{\"objectName\":\"Insight__c\",\"filters\":[...],...}"
        }
      ]
    }
  ]
}
```

**Supported Models:**
- `gpt-4o-mini` (default, fast, cost-effective)
- `gpt-4o-mini-2024-07-18` (specific version)
- `gpt-4o` (advanced reasoning)

**Error Responses:**
```json
{
  "error": {
    "message": "Error description",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

### Named Credential Configuration

**OpenAI Named Credential:**
- Label: `OpenAI`
- URL: `https://api.openai.com`
- Authentication: External Credential
- Protocol: Bearer (custom)
- Generate Authorization Header: false

**Callout Usage:**
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:OpenAI/v1/responses');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + apiKey);
```

## Query Processing Flow

### End-to-End Flow

```
User Query: "show me open banking insights from this year"
     ↓
[1] Input Validation
     - Length check (<500 chars)
     - Security patterns (prevent SOQL injection)
     ↓
[2] OpenAI Request Construction
     - Model: gpt-4o-mini
     - Instructions: Field schemas + examples
     - Input: User query
     ↓
[3] OpenAI API Call
     - HTTP POST to /v1/responses
     - Bearer token authentication
     ↓
[4] Response Parsing
     - Extract JSON from nested structure
     - Remove markdown formatting
     - Validate JSON structure
     ↓
[5] StructuredQuery Creation
     {
       "objectName": "Insight__c",
       "filters": [
         {"field":"Status__c","op":"=","value":"Open"},
         {"field":"EDGE_Product_Name__c","op":"LIKE","value":"%Banking%"},
         {"field":"CreatedDate","op":">=","value":"THIS_YEAR"}
       ],
       "fields": ["Id","Name",...],
       "limit": 100
     }
     ↓
[6] Query Normalization
     - Enforce essential fields
     - Validate field access
     - Cap limit at 200
     - Filter long text fields from WHERE
     ↓
[7] SOQL Generation
     SELECT Id, Name, Account__c, EDGE_Product_Name__c, ...
     FROM Insight__c
     WHERE Status__c = 'Open'
       AND EDGE_Product_Name__c LIKE '%Banking%'
       AND CreatedDate >= THIS_YEAR
     LIMIT 100
     ↓
[8] Query Execution
     - Field-level security enforced
     - Row-level security enforced
     ↓
[9] Result Enrichment
     - Add CSS classes for Status
     - Add CSS classes for Likelihood
     - Add account URL for navigation
     ↓
[10] Display in LWC
     - Fixed column table
     - Color-coded fields
     - Row actions enabled
```

### Date Literal Handling

**Supported Literals:**
- `TODAY`, `YESTERDAY`, `TOMORROW`
- `THIS_WEEK`, `LAST_WEEK`, `NEXT_WEEK`
- `THIS_MONTH`, `LAST_MONTH`, `NEXT_MONTH`
- `THIS_YEAR`, `LAST_YEAR`, `NEXT_YEAR`
- `LAST_90_DAYS`, `NEXT_90_DAYS`
- `LAST_N_DAYS:n`, `NEXT_N_DAYS:n`
- `N_DAYS_AGO:n`
- `LAST_N_MONTHS:n`, `NEXT_N_MONTHS:n`

**Implementation:**
```apex
// OpenAIStructuredQuery.isDateLiteral()
if (value.startsWith('TODAY') || 
    value.startsWith('THIS_YEAR') ||
    value.startsWith('LAST_N_DAYS:')) {
    return true; // Do not quote
}
```

**SOQL Output:**
```sql
-- Correct (no quotes)
WHERE CreatedDate = TODAY
WHERE CreatedDate >= LAST_N_DAYS:30

-- Incorrect (quoted)
WHERE CreatedDate = 'TODAY'  -- INVALID
```

## Testing

### Unit Tests

**Test Classes:**
- `InsightFieldSchemaTest`: Field schema functionality
- Test coverage required: 75%+ for deployment

**Run Tests:**
```bash
# Run all tests
sf apex run test --target-org <org-alias> --test-level RunLocalTests

# Run specific test
sf apex run test --target-org <org-alias> --class-names InsightFieldSchemaTest

# Run with coverage
sf apex run test --target-org <org-alias> --code-coverage --result-format human
```

**Key Test Scenarios:**
1. Field discovery and validation
2. Default field retrieval
3. Field description generation
4. Numeric and boolean field identification
5. Caching behavior
6. Invalid field handling

### Integration Testing

**Test OpenAI Integration:**
```apex
@isTest
static void testOpenAIIntegration() {
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new OpenAIMockSuccess());
    
    OpenAIStructuredQuery.StructuredQuery result = 
        OpenApiInsightsClient.getStructuredQuery('show me all insights', 'gpt-4o-mini');
    
    Test.stopTest();
    
    System.assertNotEquals(null, result);
    System.assertEquals('Insight__c', result.objectName);
}
```

**Mock HTTP Response:**
```apex
public class OpenAIMockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"output":[{"content":[{"text":"{\\"objectName\\":\\"Insight__c\\",\\"fields\\":[\\"Id\\",\\"Name\\"]}"}]}]}');
        return res;
    }
}
```

### Manual Testing Scenarios

1. **Basic Query:**
   - Input: "show me all insights"
   - Expected: All accessible insights returned

2. **Filter by Status:**
   - Input: "open insights"
   - Expected: Only Status__c = 'Open' records

3. **Product Filter:**
   - Input: "banking insights"
   - Expected: EDGE_Product_Name__c LIKE '%Banking%'

4. **Date Filter:**
   - Input: "insights from this year"
   - Expected: CreatedDate >= THIS_YEAR

5. **Combined Filters:**
   - Input: "high priority commercial cards insights"
   - Expected: Likelihood__c IN ('High','Very High') AND EDGE_Product_Name__c LIKE '%Commercial Cards%'

6. **Sorting:**
   - Input: "top 10 insights by rank"
   - Expected: ORDER BY Rank__c ASC LIMIT 10

7. **Error Handling:**
   - Input: "DROP TABLE Insight__c"
   - Expected: Validation error, no query executed

## Deployment

### Pre-Deployment Checklist

- [ ] All tests passing (75%+ coverage)
- [ ] OpenAI API key obtained
- [ ] Backup of target org completed
- [ ] Change set or deployment plan reviewed
- [ ] User permissions identified
- [ ] External Credential configuration documented

### Deployment Methods

#### Method 1: Salesforce CLI

```bash
# Validate deployment
sf project deploy start --manifest force-app/main/default/manifest/package.xml --target-org <org-alias> --dry-run

# Deploy
sf project deploy start --manifest force-app/main/default/manifest/package.xml --target-org <org-alias>

# Check deployment status
sf project deploy report --target-org <org-alias>
```

#### Method 2: Change Set

1. Create outbound change set in source org
2. Add components:
   - Apex Classes: All classes in project
   - LWC: insightCurator
   - Custom Object: Insight__c
   - Custom Fields: All Insight__c fields
   - Named Credential: OpenAI
   - External Credential: OpenAI
   - Custom Metadata: API_Setting__mdt
3. Upload change set
4. Deploy in target org
5. Configure External Credential manually

#### Method 3: Unlocked Package

```bash
# Create package
sf package create --name InsightsCurator --package-type Unlocked --path force-app

# Create version
sf package version create --package InsightsCurator --installation-key-bypass --wait 10

# Install
sf package install --package <package-version-id> --target-org <org-alias>
```

### Post-Deployment Steps

1. **Configure External Credential** (required manual step)
2. **Assign Permissions:**
   ```bash
   sf org assign permset --name InsightsCurator_Access --target-org <org-alias>
   ```
3. **Verify Configuration:**
   - Test OpenAI connectivity
   - Verify field-level security
   - Check Named Credential

4. **Add to Lightning Pages:**
   - Navigate to App Builder
   - Add Insight Curator component
   - Activate page

5. **User Training:**
   - Provide example queries
   - Document available fields
   - Explain date literals

### Deployment to Production

**Additional Steps:**
1. Schedule deployment during maintenance window
2. Notify users of new feature
3. Monitor system logs post-deployment
4. Have rollback plan ready

```bash
# Production deployment
sf project deploy start --manifest force-app/main/default/manifest/package.xml --target-org Production --test-level RunLocalTests
```

## Troubleshooting

### Common Issues

#### Issue 1: "Missing bearer or basic authentication in header"

**Symptoms:**
- HTTP 401 error
- "Missing authentication" message

**Resolution:**
1. Verify External Credential configured
2. Check API key in External Credential
3. Verify Named Credential references External Credential
4. Test API key directly:
   ```bash
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```

#### Issue 2: "Invalid JSON in OpenAI response"

**Symptoms:**
- JSON parsing error
- Response not starting with `{`

**Resolution:**
1. Check OpenAI API status
2. Verify model name is correct
3. Review system debug logs for raw response
4. Check if prompt is too long (max 500 chars user input)

#### Issue 3: "Field not accessible" / Permission Errors

**Symptoms:**
- SOQL errors
- "Field not accessible for current user"

**Resolution:**
1. Verify user has field-level security access
2. Check object permissions
3. Review profile/permission set assignments
4. Ensure fields in InsightFieldSchema whitelist

#### Issue 4: Long Text Field Filtering Error

**Symptoms:**
- SOQL error when filtering on Insight_Details__c
- "cannot filter on long text area fields"

**Resolution:**
- This is expected behavior
- Use EDGE_Product_Name__c instead for product/category filters
- Insight_Details__c can only be in SELECT, not WHERE

#### Issue 5: Date Literal Not Working

**Symptoms:**
- SOQL syntax error with date filter
- "unexpected token: 'TODAY'" error

**Resolution:**
- Verify date value not quoted in filter
- Check OpenAIStructuredQuery.isDateLiteral() logic
- Ensure value exactly matches Salesforce literal (e.g., "TODAY" not "today")

### Debug Mode

Enable debug logs:

1. **Setup** → **Debug Logs**
2. Click **New**
3. User: Your user
4. Debug Level: Create new:
   - Apex Code: DEBUG
   - Apex Profiling: INFO
   - Callout: DEBUG
   - Database: INFO
   - System: DEBUG
   - Validation: INFO
   - Visualforce: INFO
5. Duration: 30 minutes

**Review Logs:**
- Look for `=== OpenAI Request ===`
- Look for `=== OpenAI Response ===`
- Look for `=== Executing SOQL ===`
- Check for exceptions

### Monitoring

**Key Metrics:**
- OpenAI API call volume
- Average response time
- Error rate by error type
- Most common queries
- User adoption

**Create Custom Report:**
```apex
// Log query metrics to custom object
public class QueryMetrics__c {
    @AuraEnabled public String UserQuery__c;
    @AuraEnabled public Datetime QueryTime__c;
    @AuraEnabled public Integer RecordCount__c;
    @AuraEnabled public String ModelUsed__c;
    @AuraEnabled public Boolean Success__c;
}
```

## Maintenance and Extension

### Regular Maintenance Tasks

#### Weekly
- Review system debug logs for errors
- Monitor OpenAI API usage and costs
- Check user feedback

#### Monthly
- Update OpenAI API key if expired
- Review and update example queries
- Analyze query patterns for improvements

#### Quarterly
- Update field whitelist if new fields added
- Review and optimize prompts
- Test with new OpenAI models

### Adding New Fields

1. **Create field in Insight__c**
2. **Update InsightQueryService whitelist:**
   ```apex
   Set<String> allowedFields = new Set<String>{
       // ... existing fields ...
       'New_Field__c'  // Add here
   };
   ```
3. **Field will auto-populate** in AI prompts via InsightFieldSchema
4. **Deploy changes**
5. **Test queries** using new field

### Adding New OpenAI Models

1. **Update NLPQueryController.getAvailableModels():**
   ```apex
   return new List<ModelOption>{
       new ModelOption('GPT-4o Mini', 'gpt-4o-mini', true),
       new ModelOption('GPT-5', 'gpt-5', false)  // Add new model
   };
   ```
2. **Test with model**
3. **Update documentation**

### Extending Query Capabilities

#### Add New Operators

1. **Update InsightQueryService.isAllowedOperator():**
   ```apex
   Set<String> allowedOperators = new Set<String>{
       '=', '!=', '>', '>=', '<', '<=', 'IN', 'NOT IN', 'LIKE',
       'CONTAINS'  // Add new operator
   };
   ```

2. **Update OpenAIRequestBuilder instructions:**
   ```apex
   'filters: Array. Operators: =, !=, >, >=, <, <=, IN, LIKE, CONTAINS\n'
   ```

3. **Add examples** to prompt

#### Add Aggregate Queries

Current limitation: No GROUP BY support.

To add:
1. Extend StructuredQuery class with aggregation properties
2. Update OpenAI prompt with aggregation examples
3. Modify InsightQueryService.execute() to handle aggregates
4. Update LWC to display aggregate results

### Performance Optimization
Considerations for cost and performance future enhancements 

#### Reduce API Costs
- Cache common queries
- Implement query result caching (24 hours)
- Use gpt-4o-mini by default
- Batch similar queries

#### Improve Response Time
- Add query result caching
- Optimize SOQL queries with selective filters
- Add indexes on frequently filtered fields
- Implement async processing for large result sets

### Security Enhancements
Recommended Security Enhancements for future implementation 

#### Add Audit Trail
```apex
public class QueryAuditLog__c {
    @AuraEnabled public String UserQuery__c;
    @AuraEnabled public String GeneratedSOQL__c;
    @AuraEnabled public String UserId__c;
    @AuraEnabled public Datetime QueryTime__c;
}
```

#### Implement Rate Limiting
```apex
// Check query count in last hour
Integer queryCount = [SELECT COUNT() 
    FROM QueryAuditLog__c 
    WHERE UserId__c = :UserInfo.getUserId() 
    AND QueryTime__c >= :Datetime.now().addHours(-1)];

if (queryCount > 100) {
    throw new ValidationException('Rate limit exceeded');
}
```

### Support and Resources

**Documentation:**
- Salesforce DX Developer Guide
- OpenAI API Reference
- Lightning Web Components Developer Guide

**Repository:**
- GitHub: https://github.com/cmac08/InsightsCurator

**Contact:**
- Technical issues: Create GitHub issue
- Feature requests: GitHub discussions
- Security concerns: Report privately to maintainers

---

**Document Version:** 1.0  
**Last Updated:** October 2025  
**Repository:** https://github.com/cmac08/InsightsCurator