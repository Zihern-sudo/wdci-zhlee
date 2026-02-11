import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex'; // Needed for auto-refresh
import getMyApplications from '@salesforce/apex/ApplicationPortalController.getMyApplications';

const ACTIONS = [
    { label: 'Edit', name: 'edit' }
];

const COLUMNS = [
    { 
        label: 'Application ID', 
        fieldName: 'linkName', 
        type: 'url', 
        typeAttributes: { 
            label: { fieldName: 'Name' }, 
            target: '_self' 
        } 
    },
    { label: 'Program', fieldName: 'programName', type: 'text' },
    { label: 'Date Submitted', fieldName: 'CreatedDate', type: 'date' },
    { 
        label: 'Status', 
        fieldName: 'Application_Status__c', 
        type: 'text',
        cellAttributes: { class: { fieldName: 'statusColor' } }
    },
    {
        type: 'action',
        typeAttributes: { rowActions: ACTIONS },
    }
];

export default class MyApplicationList extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    @track applicationData = [];
    wiredAppResult; // Store the provisioned property to refresh it later

    @wire(getMyApplications)
    wiredApplications(result) {
        this.wiredAppResult = result; // Keep a reference for refreshApex
        const { error, data } = result;
        if (data) {
            this.applicationData = data.map(app => {
                return {
                    ...app,
                    programName: app.Applied_Program__r ? app.Applied_Program__r.Name : 'N/A',
                    linkName: `/application/${app.Id}`,
                    // Example logic for status colors
                    statusColor: app.Application_Status__c === 'Submitted' ? 'slds-text-color_success' : 'slds-text-color_default'
                };
            });
        } else if (error) {
            console.error('Error:', error);
        }
    }

    // This lifecycle hook runs when the component is re-inserted into the DOM
    renderedCallback() {
        refreshApex(this.wiredAppResult);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        if (actionName === 'edit') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Application__c',
                    actionName: 'edit'
                }
            });
        }
    }
}