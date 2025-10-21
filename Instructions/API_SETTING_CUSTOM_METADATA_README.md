# API Setting Custom Metadata

This directory contains the custom metadata type `API_Setting__mdt` and its records that were retrieved from the org and stored in source control.

## Files

- `customMetadata/API_Setting__mdt.metadata-meta.xml` - Metadata type definition
- `customMetadata/API_Setting__mdt.metadata` - Sample metadata type definition
- `customMetadata/API_Setting__mdt.API_Setting_1.metadata` - Sample record

## Structure

The custom metadata type follows the standard Salesforce custom metadata structure:
- The metadata type is named `API_Setting__mdt`
- Records are stored with the naming convention: `API_Setting__mdt.{RecordName}.metadata`
- Each record contains fields that store API-related settings

## Usage

This custom metadata can be used to store API configuration settings that can be referenced by Apex classes, flows, or other components in the Salesforce org.
