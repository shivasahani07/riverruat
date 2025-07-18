import { LightningElement, track } from 'lwc';
import uId from '@salesforce/user/Id';
import userCheckin from '@salesforce/apex/UserTrackingcontroller.UserCheckin';
import userCheckout from '@salesforce/apex/UserTrackingcontroller.UserCheckout';
import checkUserStatus from '@salesforce/apex/UserTrackingcontroller.OnpageLoad';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UserTracking extends LightningElement {
    userId = uId;
    @track userStatus = {};
    @track showCheckoutPopup = false;
    @track showCheckoutSpinner = false;

    get isCheckinDisabled() {
        return this.userStatus.checkinDisabled || false;
    }

    get isCheckoutDisabled() {
        return this.userStatus.checkoutDisabled || false;
    }

    get areDetailsVisible() {
        return this.userStatus.areDetailsVisible || false;
    }

    get breakTimeLabel() {
        return this.userStatus.breakTimeStatus === 'On Break' ? 'End Break Time' : 'Start Break Time';
    }

    get disableBreakButton() {
        return !this.areDetailsVisible;
    }

    connectedCallback() {
        this.loadUserStatus();
    }

    async loadUserStatus() {
        try {
            const result = await checkUserStatus({ userId: this.userId });
            this.userStatus = {
                checkinDisabled: result.checkin,
                checkoutDisabled: result.checkout,
                areDetailsVisible: result.checkin && result.LoggedInAuditOfficer?.IsActive__c,
                breakTimeStatus: result.AOAvailableStatus || '',
            };
        } catch (error) {
            console.error('Error fetching user status:', error);
        }
    }

    async handleCheckin() {
        try {
            const result = await userCheckin({ userId: this.userId });
            this.showToast('Checkin', result.eventStatus, 'success');
            if (result.eventStatus === 'Checkin successful') {
                this.loadUserStatus();
            }
        } catch (error) {
            console.error('Checkin error:', error);
        }
    }

    handleCheckoutPopup() {
        this.showCheckoutPopup = true;
    }

    dismissCheckoutPopup() {
        this.showCheckoutPopup = false;
    }

    async handleCheckout() {
        this.showCheckoutSpinner = true;
        try {
            const result = await userCheckout({ userId: this.userId });
            this.showToast('Checkout', result, 'success');
            this.showCheckoutPopup = false;
            this.loadUserStatus();
        } catch (error) {
            console.error('Checkout error:', error);
        } finally {
            this.showCheckoutSpinner = false;
        }
    }

    async handleBreakTime() {
        // Simulate a call to break time logic
        try {
            const breakStatus = this.breakTimeLabel === 'Start Break Time' ? 'On Break' : 'Available';
            this.userStatus.breakTimeStatus = breakStatus;
            this.showToast('Break Time', `Break time ${breakStatus}`, 'info');
        } catch (error) {
            console.error('Break time error:', error);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: 'dismissable' }));
    }
}