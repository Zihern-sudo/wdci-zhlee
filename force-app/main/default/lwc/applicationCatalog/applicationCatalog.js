import { LightningElement, wire, track } from 'lwc';
import getRequirements from '@salesforce/apex/ProgramRequirementController.getRequirements';
import getUserNationality from '@salesforce/apex/ApplicationPortalController.getUserNationality';

export default class ApplicationCatalog extends LightningElement {
    @track requirements;
    @track userNationality;
    @track error;

    @wire(getUserNationality)
    wiredNationality({ error, data }) {
        if (data) {
            this.userNationality = data;
        } else if (error) {
            this.error = 'Failed to load nationality.';
        }
    }

    @wire(getRequirements, { nationality: '$userNationality' })
    wiredReqs({ error, data }) {
        if (data) {
            this.requirements = data;
        } else if (error) {
            this.error = 'Failed to load requirements.';
        }
    }

    // Returns 'Domestic' or 'International' for the sub-heading
    get categoryHeader() {
        if (!this.userNationality) return '';
        return (this.userNationality === 'Malaysian' || this.userNationality === 'Domestic') 
            ? 'Domestic' 
            : 'International';
    }

    get hasRequirements() {
        return this.requirements && this.requirements.length > 0;
    }
}