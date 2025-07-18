import { LightningElement, api, track, wire } from 'lwc';
import getLineItems from '@salesforce/apex/DiscrepancyController.getLineItems';
import updateSupportingMedia from '@salesforce/apex/DiscrepancyController.updateSupportingMedia';
import getUserProfile from '@salesforce/apex/DiscrepancyController.getUserProfile';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AddSupportingMedia extends LightningElement {
    @api recordId;
    @track lineItems = [];
    @track mediaUpdates = {};
    isLoading = true;
    userProfile = '';
    @track isSPMUser = false;
    @track isWarehouseUser = false;
    @track isSalesManager = false;

    connectedCallback() {
        this.refreshComponent();
        const storedProfile = sessionStorage.getItem('userProfile');

        if (storedProfile) {
            this.setUserFlags(storedProfile);
        } else {
            getUserProfile()
                .then(result => {
                    this.setUserFlags(result);
                    sessionStorage.setItem('userProfile', result);
                })
                .catch(() => this.showToast('Error', 'Failed to fetch user profile', 'error'));
        }
    }

    setUserFlags(profile) {
        this.isSPMUser = (/*profile === 'System Administrator' ||*/ profile === 'CQA Profile');
        this.isWarehouseUser = (profile === 'Warehouse Profile');
        this.isSalesManager = (profile === 'Sales Manager (Partner)');
        this.systemAdmin = (profile === 'System Administrator');
        this.userProfile = profile;
    }

    refreshComponent() {
        this.isLoading = true;
        setTimeout(() => (this.isLoading = false), 3000);
    }

    @wire(getLineItems, { discrepancyId: '$recordId' })
    wiredLineItems({ data, error }) {
        if (data) {
            this.lineItems = data.map(item => ({
                ...item,
                approveStyle: 'neutral',
                rejectStyle: 'neutral',
                feedback: item.Feedback__c || ''
            }));
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error', 'Failed to fetch line items', 'error');
            this.isLoading = false;
        }
    }

    handleInputChange(event) {
        const itemId = event.target.dataset.id;
        const mediaUrl = event.target.value;

        this.lineItems = this.lineItems.map(item => {
            if (item.Id === itemId) {
                return { ...item, Supporting_Media__c: mediaUrl };
            }
            return item;
        });

        this.mediaUpdates[itemId] = {
            ...this.mediaUpdates[itemId],
            Supporting_Media__c: mediaUrl
        };
    }

    // handleApproval(event) {
    //     const itemId = event.target.dataset.id;
    //     const action = event.target.name;
    
    //     console.log('Approval clicked:', action, 'for item:', itemId);
    //     console.log('Is Sales Manager:', this.isSalesManager);
    
    //     this.lineItems = this.lineItems.map(item => {
    //         if (item.Id === itemId) {
    //             let updatedItem = { ...item };
    
    //             if (this.isSalesManager) {
    //                 updatedItem.approveStyle = action === 'approve' ? 'brand' : 'neutral';
    //                 updatedItem.rejectStyle = action === 'reject' ? 'destructive' : 'neutral';
    
                    
    //                 if (action === 'approve') {
    //                     updatedItem.Status__c = 'Under SPM Review';
    //                 } else if (action === 'reject') {
    //                     updatedItem.Status__c = 'New';
    //                 }
    
                    
    //                 this.mediaUpdates[itemId] = {
    //                     ...this.mediaUpdates[itemId],  
    //                     status: updatedItem.Status__c,
    //                     supportingUrl:updatedItem.Supporting_Media__c
    //                 };
    
    //                 console.log('Updated mediaUpdates:', this.mediaUpdates);
    //             }
    
    //             return updatedItem;
    //         }
    //         return item;
    //     });
    
    //     console.log('Final lineItems:', JSON.stringify(this.lineItems));
    // }
    handleApproval(event) {
        const itemId = event.target.dataset.id;
        const action = event.target.name;
    
        console.log('Approval clicked:', action, 'for item:', itemId);
        console.log('User Profile:', this.userProfile);
    
        this.lineItems = this.lineItems.map(item => {
            if (item.Id === itemId) {
                let updatedItem = { ...item };
    
                if (this.isSalesManager) {
                    updatedItem.approveStyle = action === 'approve' ? 'brand' : 'neutral';
                    updatedItem.rejectStyle = action === 'reject' ? 'destructive' : 'neutral';
    
                    updatedItem.Status__c = action === 'approve' ? 'Under SPM Review' : 'New';
    
                    this.mediaUpdates[itemId] = {
                        ...this.mediaUpdates[itemId],  
                        status: updatedItem.Status__c,
                        supportingUrl: updatedItem.Supporting_Media__c
                    };
                } 
    
                if (this.isSPMUser || this.systemAdmin) {  
                    updatedItem.approveStyle = action === 'approve' ? 'brand' : 'neutral';
                    updatedItem.rejectStyle = action === 'reject' ? 'destructive' : 'neutral';
    
                    updatedItem.Spare_Approval__c = action === 'approve' ? 'Approved' : 'Rejected';
    
                    this.mediaUpdates[itemId] = {
                        ...this.mediaUpdates[itemId],
                        status: updatedItem.Spare_Approval__c,
                        feedback: updatedItem.feedback
                    };
    
                    console.log('Parts Manager Update:', this.mediaUpdates[itemId]); 
                }
    
                if (this.isWarehouseUser) {  
                    updatedItem.approveStyle = action === 'approve' ? 'brand' : 'neutral';
                    updatedItem.rejectStyle = action === 'reject' ? 'destructive' : 'neutral';
    
                    updatedItem.Warehouse_Approval__c = action === 'approve' ? 'Approved' : 'Rejected';
    
                    this.mediaUpdates[itemId] = {
                        ...this.mediaUpdates[itemId],
                        status: updatedItem.Warehouse_Approval__c,
                        feedback: updatedItem.feedback
                    };
    
                    console.log('Warehouse Profile Update:', this.mediaUpdates[itemId]); 
                }
    
                return updatedItem;
            }
            return item;
        });
    
        console.log('Final lineItems:', JSON.stringify(this.lineItems));
    }
    
    

    handleFeedbackChange(event) {
        const itemId = event.target.dataset.id;
        const feedbackValue = event.target.value;

        this.lineItems = this.lineItems.map(item => {
            if (item.Id === itemId) {
                return { ...item, feedback: feedbackValue };
            }
            return item;
        });

        this.mediaUpdates[itemId] = {
            ...this.mediaUpdates[itemId],
            feedback: feedbackValue
        };
    }

    async handleAddSupportingMedia() {
        if (!this.userProfile) {
            this.showToast('Error', 'User profile is not available!', 'error');
            return;
        }
    
        if (Object.keys(this.mediaUpdates).length === 0) {
            this.showToast('Warning', 'No changes detected!', 'warning');
            return;
        }
    
        console.log('Final mediaUpdates being sent:', JSON.stringify(this.mediaUpdates));
    
        this.isLoading = true;
        try {
            await updateSupportingMedia({ mediaUpdates: this.mediaUpdates, profileName: this.userProfile });
    
            this.showToast('Success', 'Updated successfully!', 'success');
            this.handleExit();
            window.location.reload();
        } catch (error) {
            console.error('Error updating media:', error);
            this.showToast('Error', 'Failed to update media', 'error');
        } finally {
            this.isLoading = false;
        }
    }
    

    handleExit() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}