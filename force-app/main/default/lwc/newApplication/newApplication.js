import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; // Added for auto-navigation
import submitApplication from '@salesforce/apex/ApplicationPortalController.submitApplication';
import getRequirements from '@salesforce/apex/ProgramRequirementController.getRequirements';
import getLoggedInContact from '@salesforce/apex/ApplicationPortalController.getLoggedInContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewApplicationForm extends NavigationMixin(LightningElement) {
    @track currentStep = 1;
    @track applicationId;
    @track requirements = [];
    @track nationalityLabel = '';
    @track appData = {};

    @wire(getLoggedInContact)
    wiredContact({ error, data }) {
        if (data) {
            this.appData = {
                firstName: data.FirstName,
                lastName: data.LastName,
                email: data.Email,
                mobile: data.MobilePhone,
                dob: data.Birthdate,
                gender: data.Gender__c,
                nationality: data.Nationality__c
            };
        } else if (error) {
            console.error('Error fetching contact:', error);
        }
    }

    genderOptions = [{ label: 'Male', value: 'Male' }, { label: 'Female', value: 'Female' }, { label: 'Not to Disclose', value: 'Not to Disclose' }];
    nationalityOptions = [{ label: 'Domestic (Malaysian)', value: 'Malaysian' }, { label: 'International (Others)', value: 'Singaporean' }];
    eduOptions = [{ label: 'High School', value: 'High School' }, { label: 'Pre U', value: 'Pre U' }, { label: 'Primary School', value: 'Primary School' }];
    sourceOptions = [{ label: 'Telemarketing', value: 'Telemarketing' }, { label: 'Website', value: 'Website' }, { label: 'Friends', value: 'Friends' }, { label: 'Social Media', value: 'Social Media' }];

    get isStepOne() { return this.currentStep === 1; }
    get isStepTwo() { return this.currentStep === 2; }
    get isStepThree() { return this.currentStep === 3; }

    handleChange(event) {
        const field = event.target.dataset.id;
        this.appData[field] = event.target.value;
    }

    handleNext() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Attention', 'Please fill in all required fields.', 'warning');
            return;
        }

        const category = this.appData.nationality === 'Malaysian' ? 'Domestic' : 'International';
        this.nationalityLabel = category;

        submitApplication({ appData: this.appData })
            .then(result => {
                this.applicationId = result;
                return getRequirements({ nationality: category });
            })
            .then(data => {
                this.requirements = data;
                this.currentStep = 2;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleUploadFinished(event) {
        this.showToast('Success', event.detail.files.length + ' files uploaded successfully', 'success');
    }

    handleFinish() {
        this.currentStep = 3;

        // Auto-navigate to My Applications page after 3 seconds
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'My_Applications__c' // Ensure this matches the API Name of your page in Experience Builder
                }
            });
        }, 3000);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}