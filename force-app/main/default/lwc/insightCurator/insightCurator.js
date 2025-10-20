import { LightningElement, track } from 'lwc';
import processPrompt from '@salesforce/apex/NLPQueryController.processPrompt';

export default class InsightCurator extends LightningElement {
    @track prompt = '';
    @track modelName = '';
    @track data = [];
    @track loading = false;
    @track error;

    columns = [
        { label: 'Insight', fieldName: 'Name' },
        { label: 'Account', fieldName: 'Account__c' },
        { label: 'Product', fieldName: 'EDGE_Product_Name__c' },
        { label: 'Likelihood', fieldName: 'Likelihood__c', type: 'number' },
        { label: 'Est. Annual Revenue', fieldName: 'Estimated_Annual_Revenue__c', type: 'currency' },
        { label: 'Rank', fieldName: 'Rank__c', type: 'number' },
        { label: 'Status', fieldName: 'Status__c' }
    ];

    handlePromptChange(event) {
        this.prompt = event.target.value;
    }

    handleModelChange(event) {
        this.modelName = event.target.value;
    }

    async handleSubmit() {
        this.error = undefined;
        this.loading = true;
        this.data = [];
        try {
            const result = await processPrompt({ prompt: this.prompt, modelName: this.modelName });
            this.data = result || [];
            console.log(this.data);
        } catch (e) {
            // Enhanced error handling for better debugging
            if (e && e.body && e.body.message) {
                // Check for authentication-related errors
                if (e.body.message.includes('bearer') || e.body.message.includes('authentication')) {
                    this.error = 'Authentication error: Please verify your OpenAI API key is correctly configured in External Credentials.';
                } else {
                    this.error = e.body.message;
                }
            } else if (e && e.message) {
                // Check for common authentication errors
                if (e.message.includes('bearer') || e.message.includes('authentication')) {
                    this.error = 'Authentication error: Please verify your OpenAI API key is correctly configured in External Credentials.';
                } else {
                    this.error = e.message;
                }
            } else {
                this.error = 'An unknown error occurred while processing your request.';
            }
        } finally {
            this.loading = false;
        }
    }
}
