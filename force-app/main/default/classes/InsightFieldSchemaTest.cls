/**
 * Test class for InsightFieldSchema
 */
@isTest
private class InsightFieldSchemaTest {
    
    @isTest
    static void testGetAllowedFields() {
        Test.startTest();
        Set<String> allowedFields = InsightFieldSchema.getAllowedFields();
        Test.stopTest();
        
        // Verify standard fields are included
        System.assert(allowedFields.contains('Id'), 'Should contain Id field');
        System.assert(allowedFields.contains('Name'), 'Should contain Name field');
        
        // Verify we got a reasonable number of fields
        System.assert(allowedFields.size() > 0, 'Should return at least some fields');
        
        System.debug('Total accessible fields: ' + allowedFields.size());
        System.debug('Fields: ' + allowedFields);
    }
    
    @isTest
    static void testGetDefaultFields() {
        Test.startTest();
        List<String> defaultFields = InsightFieldSchema.getDefaultFields();
        Test.stopTest();
        
        // Verify Id and Name are always included
        System.assert(defaultFields.contains('Id'), 'Should contain Id in defaults');
        System.assert(defaultFields.contains('Name'), 'Should contain Name in defaults');
        
        System.debug('Default fields: ' + defaultFields);
    }
    
    @isTest
    static void testGetFieldDescriptions() {
        Test.startTest();
        String descriptions = InsightFieldSchema.getFieldDescriptions();
        Test.stopTest();
        
        // Verify descriptions are generated
        System.assert(String.isNotBlank(descriptions), 'Should return field descriptions');
        System.assert(descriptions.contains('AVAILABLE INSIGHT__C FIELDS'), 'Should contain header');
        System.assert(descriptions.contains('Id'), 'Should mention Id field');
        
        System.debug('Field descriptions length: ' + descriptions.length());
        System.debug('Field descriptions:\n' + descriptions);
    }
    
    @isTest
    static void testIsValidField() {
        Test.startTest();
        
        // Test valid fields
        System.assertEquals(true, InsightFieldSchema.isValidField('Id'), 'Id should be valid');
        System.assertEquals(true, InsightFieldSchema.isValidField('Name'), 'Name should be valid');
        
        // Test invalid fields
        System.assertEquals(false, InsightFieldSchema.isValidField('NonExistent__c'), 
            'NonExistent__c should be invalid');
        System.assertEquals(false, InsightFieldSchema.isValidField(null), 
            'Null should be invalid');
        System.assertEquals(false, InsightFieldSchema.isValidField(''), 
            'Empty string should be invalid');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetNumericFields() {
        Test.startTest();
        Set<String> numericFields = InsightFieldSchema.getNumericFields();
        Test.stopTest();
        
        System.assert(numericFields.size() >= 0, 'Should return numeric fields set');
        System.debug('Numeric fields: ' + numericFields);
        
        // If we have numeric fields, verify they don't include obvious non-numeric ones
        if (!numericFields.isEmpty()) {
            System.assertEquals(false, numericFields.contains('Name'), 
                'Name should not be in numeric fields');
        }
    }
    
    @isTest
    static void testGetBooleanFields() {
        Test.startTest();
        Set<String> booleanFields = InsightFieldSchema.getBooleanFields();
        Test.stopTest();
        
        System.assert(booleanFields.size() >= 0, 'Should return boolean fields set');
        System.debug('Boolean fields: ' + booleanFields);
    }
    
    @isTest
    static void testIsNumericField() {
        Test.startTest();
        
        // Test obvious non-numeric field
        System.assertEquals(false, InsightFieldSchema.isNumericField('Name'), 
            'Name should not be numeric');
        
        Test.stopTest();
    }
    
    @isTest
    static void testIsBooleanField() {
        Test.startTest();
        
        // Test obvious non-boolean field
        System.assertEquals(false, InsightFieldSchema.isBooleanField('Name'), 
            'Name should not be boolean');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCachingBehavior() {
        // Call multiple times to verify caching works without errors
        Test.startTest();
        
        Set<String> fields1 = InsightFieldSchema.getAllowedFields();
        Set<String> fields2 = InsightFieldSchema.getAllowedFields();
        String desc1 = InsightFieldSchema.getFieldDescriptions();
        String desc2 = InsightFieldSchema.getFieldDescriptions();
        
        Test.stopTest();
        
        // Verify results are consistent
        System.assertEquals(fields1.size(), fields2.size(), 
            'Multiple calls should return same number of fields');
        System.assertEquals(desc1, desc2, 
            'Multiple calls should return same descriptions');
    }
}