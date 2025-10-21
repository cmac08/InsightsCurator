# External Credential Setup for OpenAI Integration

This document explains how to properly configure the External Credential for the OpenAI integration with OpenAI.

## Current Configuration

The project includes:
1. `OpenAI.namedCredential-meta.xml` - Configures the Named Credential
2. `OpenAI.externalCredential-meta.xml` - Configures the External Credential

## Corrected Protocol Values

Note: The correct protocol values are:
- Named Credential protocol: `Bearer` (not `BearerToken`)
- External Credential authenticationProtocol: `Bearer` (not `BearerToken`)

## Required Manual Setup

The API key for the External Credential must be set manually in Salesforce:

1. Navigate to **Setup** → **Security** → **External Credentials**
2. Find or create the "OpenAI" External Credential
3. Click **Manage Secrets**
4. Add a new secret with:
   - Label: "OpenAI API Key"
   - Type: "PlainText"
   - Secret Value: Your actual OpenAI API key (starting with sk-...)

## Why This Is Necessary

Salesforce External Credentials with Bearer Token authentication store sensitive information like API keys in a secure manner. This information cannot be included directly in metadata files for security reasons.

## Testing the Configuration

After setting up the API key:
1. Deploy all metadata to your org
2. Test the integration through the LWC component
3. Verify that the Named Credential can successfully make calls to OpenAI

## Troubleshooting

If you still encounter authentication errors:
1. Verify the API key is correctly set in the External Credential
2. Check that the Named Credential references the correct External Credential
3. Ensure the Named Credential's protocol is set to "BearerToken"
4. Confirm the endpoint URL is correct (https://api.openai.com)
