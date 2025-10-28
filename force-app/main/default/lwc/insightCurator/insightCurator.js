import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processPrompt from '@salesforce/apex/NLPQueryController.processPrompt';
import getAvailableModels from '@salesforce/apex/NLPQueryController.getAvailableModels';
import getExampleQueries from '@salesforce/apex/NLPQueryController.getExampleQueries';

export default class insightCurator extends LightningElement {
    // Input values
    @track prompt = '';
    @track selectedModel = 'gpt-4o-mini';
    
    // State management
    @track loading = false;
    @track errorMessage = '';
    @track hasSearched = false;
    @track showQuery = false;
    
    // Results
    @track results = [];
    @track recordCount = 0;
    @track generatedQuery = '';
    @track lastQueryStatus = ''; // "Success" or "Failed"
    
    // Options
    @track modelOptions = [];
    @track exampleQueries = [];
    
    // Data table columns - fixed columns showing most useful information
    columns = [
        { 
            label: 'Insight Name', 
            fieldName: 'insightUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            initialWidth: 180
        },
        { 
            label: 'Account', 
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'accountName' },
                target: '_blank'
            },
            initialWidth: 150
        },
        { 
            label: 'Solution', 
            fieldName: 'EDGE_Product_Name__c', 
            type: 'text',
            initialWidth: 150
        },
        { 
            label: 'Status', 
            fieldName: 'Status__c', 
            type: 'text',
            cellAttributes: { 
                class: { fieldName: 'statusClass' }
            },
            initialWidth: 120
        },
        { 
            label: 'Likelihood', 
            fieldName: 'Likelihood__c', 
            type: 'text',
            cellAttributes: { 
                class: { fieldName: 'likelihoodClass' }
            },
            initialWidth: 120
        },
        { 
            label: 'Rank', 
            fieldName: 'Rank__c', 
            type: 'number',
            typeAttributes: { 
                minimumFractionDigits: 1,
                maximumFractionDigits: 1
            },
            initialWidth: 80
        },
        { 
            label: 'Est. Revenue', 
            fieldName: 'Estimated_Annual_Revenue__c', 
            type: 'text',
            initialWidth: 130
        },
        { 
            label: 'Details', 
            fieldName: 'Insight_Details__c', 
            type: 'text',
            wrapText: true,
            initialWidth: 200
        },
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions },
            initialWidth: 60
        }
    ];

    // Lifecycle hooks
    connectedCallback() {
        this.loadModels();
        this.loadExamples();
    }

    // Computed properties
    get isSubmitDisabled() {
        return this.loading || !this.prompt;
    }

    get showResults() {
        return this.hasSearched && !this.loading && !this.errorMessage && this.results.length >= 0;
    }

    get showExamples() {
        return !this.hasSearched && this.exampleQueries.length > 0;
    }

    get recordCountPlural() {
        return this.recordCount === 1 ? '' : 's';
    }

    get queryToggleIcon() {
        return this.showQuery ? 'utility:chevrondown' : 'utility:chevronright';
    }

    // Computed banner to always show success/failure next to the generated query
    get generatedQueryWithStatus() {
        if (!this.hasSearched) {
            return '';
        }
        const status = this.lastQueryStatus ? `[${this.lastQueryStatus}] ` : '';
        return `${status}${this.generatedQuery || ''}`;
    }

    // Load available models
    async loadModels() {
        try {
            const models = await getAvailableModels();
            this.modelOptions = models.map(model => ({
                label: model.label,
                value: model.value
            }));
            
            // Set default model
            const defaultModel = models.find(m => m.isDefault);
            if (defaultModel) {
                this.selectedModel = defaultModel.value;
            }
        } catch (error) {
            console.error('Error loading models:', error);
            // Silent fail - use default model
        }
    }

    // Load example queries
    async loadExamples() {
        try {
            this.exampleQueries = await getExampleQueries();
        } catch (error) {
            console.error('Error loading examples:', error);
            // Silent fail - examples are optional
        }
    }

    // Event handlers
    handlePromptChange(event) {
        this.prompt = event.target.value;
        this.errorMessage = '';
    }

    handleModelChange(event) {
        this.selectedModel = event.detail.value;
    }

    handleExampleClick(event) {
        this.prompt = event.target.dataset.query;
        this.handleSubmit();
    }

    handleQueryToggle() {
        // this.showQuery = !this.showQuery;
        this.showQuery = true;

    }

    // Main submit handler
    async handleSubmit() {
        if (!this.prompt) {
            this.showToast('Error', 'Please enter a query', 'error');
            return;
        }

        this.loading = true;
        this.errorMessage = '';
        this.results = [];
        this.recordCount = 0;
        this.generatedQuery = '';
        this.lastQueryStatus = '';
        this.hasSearched = true;

        try {
            const result = await processPrompt({
                prompt: this.prompt,
                modelName: this.selectedModel
            });

            console.log('Query result:', result);

            // Process and enrich results with formatting classes
            this.results = this.enrichResults(result.records || []);
            this.recordCount = result.recordCount || 0;
            this.generatedQuery = result.query || '';
            this.lastQueryStatus = result.success ? 'Success' : 'Failed';

            // Show success message
            this.showToast(
                'Success',
                result.message || `Found ${this.recordCount} record${this.recordCountPlural}`,
                'success'
            );

        } catch (error) {
            console.error('Error processing query:', error);
            
            this.errorMessage = error.body?.message || 
                               error.message || 
                               'An unexpected error occurred';
            // Ensure the Generated Query panel still communicates failure and try to surface the attempted query
            this.lastQueryStatus = 'Failed';

            // Attempt to extract the attempted/generated SOQL from common Apex error shapes.
            // Fall back to any previously set value to keep string type stable.
            const attemptedQuery =
                error?.body?.details?.query ||
                error?.body?.query ||
                error?.query ||
                // Some handlers may serialize extra info in message as JSON; try to parse safely
                (() => {
                    try {
                        const maybeJson = JSON.parse(error?.body?.message ?? error?.message ?? '{}');
                        return maybeJson?.query || null;
                    } catch (e) {
                        return null;
                    }
                })();

            if (attemptedQuery) {
                this.generatedQuery = attemptedQuery;
            } else {
                // Preserve any previously known generated query (if it was set before failure)
                this.generatedQuery = this.generatedQuery || '';
            }
            
            this.showToast(
                'Query Failed',
                this.errorMessage,
                'error',
                'sticky'
            );
        } finally {
            this.loading = false;
        }
    }

    // Update columns based on returned record fields
    enrichResults(records) {
        if (!records || records.length === 0) {
            return [];
        }

        return records.map(record => {
            // Create a copy of the record
            const enrichedRecord = { ...record };

            // Add Insight URL for clickable Insight Name
            if (record.Id) {
                enrichedRecord.insightUrl = '/lightning/r/Insight__c/' + record.Id + '/view';
            }

            // Add account URL and Name label for linking to the account record
            if (record.Account__c) {
                enrichedRecord.accountUrl = '/lightning/r/Account/' + record.Account__c + '/view';
            }
            // Prefer relational name if provided by the query
            if (record.Account__r && record.Account__r.Name) {
                enrichedRecord.accountName = record.Account__r.Name;
            }

            // Add CSS classes based on Status
            if (record.Status__c) {
                const status = record.Status__c.toLowerCase();
                if (status === 'open') {
                    enrichedRecord.statusClass = 'slds-text-color_success';
                } else if (status === 'closed') {
                    enrichedRecord.statusClass = 'slds-text-color_weak';
                } else if (status === 'deferred') {
                    enrichedRecord.statusClass = 'slds-text-color_default';
                } else if (status === 'archived') {
                    enrichedRecord.statusClass = 'slds-text-color_weak';
                }
            }

            // Add CSS classes based on Likelihood
            if (record.Likelihood__c) {
                const likelihood = record.Likelihood__c.toLowerCase();
                if (likelihood === 'very high') {
                    enrichedRecord.likelihoodClass = 'slds-text-color_success slds-text-title_bold';
                } else if (likelihood === 'high') {
                    enrichedRecord.likelihoodClass = 'slds-text-color_success';
                } else if (likelihood === 'medium') {
                    enrichedRecord.likelihoodClass = 'slds-text-color_default';
                } else if (likelihood === 'low') {
                    enrichedRecord.likelihoodClass = 'slds-text-color_weak';
                }
            }

            return enrichedRecord;
        });
    }

    // Row actions for data table
    getRowActions(row, doneCallback) {
        const actions = [
            { label: 'View', name: 'view' },
            { label: 'Edit', name: 'edit' }
        ];
        doneCallback(actions);
    }

    // Handle row actions
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.navigateToRecord(row.Id);
                break;
            case 'edit':
                this.navigateToRecord(row.Id, 'edit');
                break;
            default:
                break;
        }
    }

    // Navigate to record
    navigateToRecord(recordId, mode = 'view') {
        const url = mode === 'edit' 
            ? `/lightning/r/Insight__c/${recordId}/edit`
            : `/lightning/r/Insight__c/${recordId}/view`;
        
        window.open(url, '_blank');
    }

    // Show toast notification
    showToast(title, message, variant, mode = 'dismissable') {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}
