# InsightsCurator Project Overview

This repository contains the InsightsCurator application, which leverages Salesforce and AI to provide insights to sales teams.

## Features

- Insight generation from Salesforce data
- Natural Language Processing queries
- AI-powered analysis

## Custom Metadata

This project includes custom metadata for API settings:

- **API_Setting__mdt**: Custom metadata type for storing API configuration settings
- Contains sample record: API_Setting_1

## Getting Started

To set up this project locally, you'll need to:

1. Install Salesforce CLI
2. Authorize a Salesforce org
3. Deploy the metadata
4. Configure external credentials for OpenAI

## Deployment

To deploy this application to a Salesforce org, run:

```bash
sf deploy metadata
```

## Configuration

Before deploying, make sure to configure the following:

- External Credentials for OpenAI
- Named Credentials for API access
- API Setting custom metadata records

## License

This project is licensed under the MIT License.
