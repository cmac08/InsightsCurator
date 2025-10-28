# Deployment Instructions for OpenAPI Integration

This guide explains how to deploy and configure the OpenAPI integration with Salesforce.

## Prerequisites

1. Salesforce DX CLI installed
2. A Dev Hub org configured
3. A scratch org or sandbox with the required permissions
4. An OpenAI API key

## Deployment Steps

### 1. Deploy Metadata

```bash
# Deploy all metadata to your org
sf deploy metadata --source-dir force-app --target-org your-org-alias
```

### 2. Configure External Credentials

The API key must be configured manually in Salesforce:

1. Navigate to **Setup** → **Security** → **External Credentials**
2. Find or create the "OpenApi" External Credential
3. Click **Manage Secrets**
4. Add a new secret with:
   - Label: "OpenAI API Key"
   - Type: "PlainText"
   - Secret Value: Your actual OpenAI API key (starting with sk-...)

### 3. Test the Integration

1. Open the Lightning App Builder
2. Add the Insight Curator component to a page
3. Enter a natural language query (e.g., "Show me insights with likelihood > 80%")
4. Click "Run"

## Troubleshooting

### Authentication Errors

If you encounter "Missing bearer or basic authentication in header" errors:

1. Verify the API key is correctly set in the External Credential
2. Check that the Named Credential references the correct External Credential
3. Ensure the Named Credential's protocol is set to "Bearer"
4. Confirm the endpoint URL is correct (https://api.openai.com)

### Common Issues

1. **Permission Issues**: Ensure the user profile has access to the Named Credential
2. **Network Access**: Make sure the org can reach https://api.openai.com
3. **API Quotas**: Monitor your OpenAI API usage limits

## File Structure

```
force-app/
├── main/
│   ├── default/
│   │   ├── classes/
│   │   │   ├── OpenAIInsightsClient.cls
│   │   │   ├── InsightQueryService.cls
│   │   │   └── NLPQueryController.cls
│   │   ├── lwc/
│   │   │   └── insightCurator/
│   │   │       ├── insightCurator.js
│   │   │       ├── insightCurator.html
│   │   │       └── insightCurator.js-meta.xml
│   │   ├── namedCredentials/
│   │   │   └── OpenAI.namedCredential-meta.xml
│   │   └── externalCredentials/
│   │       ├── OpenAI.externalCredential-meta.xml
│   └── main/default/objects/Insight__c/
```

## Components Overview

- **OpenAIInsightsClient.cls**: Handles communication with OpenAI API
- **InsightQueryService.cls**: Processes structured queries and generates SOQL
- **NLPQueryController.cls**: Apex REST controller that bridges LWC to backend logic
- **insightCurator**: LWC component for user interaction
- **NamedCredential**: Configures the connection to OpenAI with Bearer Token auth
- **ExternalCredential**: Stores the API key securely
