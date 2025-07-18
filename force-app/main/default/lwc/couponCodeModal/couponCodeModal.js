import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import STATUS_FIELD from '@salesforce/schema/Order.Status';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Order.AccountId';
import COUPON_APPLIED from '@salesforce/schema/Order.Is_Coupon_Applied__c';
import NO_COUPON from '@salesforce/schema/Order.Customer_Has_No_Coupon__c';
import getAccountCasesWithCoupons from '@salesforce/apex/CouponCodeRedemptionhandler.getAccountCasesWithCoupons';
import getOrderItems from '@salesforce/apex/CouponCodeRedemptionhandler.getOrderItems';
import markCustomerHasNoCoupon from '@salesforce/apex/CouponCodeRedemptionhandler.markCustomerHasNoCoupon';
import applyCouponToOrder from '@salesforce/apex/CouponCodeRedemptionhandler.applyCouponToOrder';


export default class CouponCodeModal extends LightningElement {
    @api recordId;
    @track ISShowModel = false;
    @track trackCount=1
    @track couponCode = '';
    @track isLoading = false;
    orderAccountId = null;
    @track matchedCoupon = null;
    orderItems = [];
    accountCases = [];

    connectedCallback() {
        const url = window.location.href.toString();
        const queryParams = url.split("&");
        const recordIdParam = queryParams.find(param => param.includes("recordId"));

        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");
            if (recordIdKeyValue.length === 2) {
                this.recordId = recordIdKeyValue[1];
            }
        } else {
            const match = url.match(/\/Order\/([^/]+)/);
            if (match) {
                this.recordId = match[1];
            }
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, ACCOUNT_ID_FIELD, COUPON_APPLIED, NO_COUPON] })
    wiredRecord({ error, data }) {
        debugger;
        if (data) {
            const status = data.fields.Status.value;
            this.orderAccountId = data.fields.AccountId?.value;
            const isCouponApplied = data.fields.Is_Coupon_Applied__c?.value;
            this.couponAppliedField = isCouponApplied;
            const isNoCoupon = data.fields.Customer_Has_No_Coupon__c?.value;
            this.NoCoupon = isNoCoupon;
            if (status === 'Pre Invoice' && this.couponAppliedField === false && this.NoCoupon === false) {
                this.checkIfCouponAvailable(this.orderAccountId);
            }
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    handleCouponChange(event) {
        this.couponCode = event.target.value.trim();
    }

    async handleApplyCoupon() {
        debugger;
        if (!this.orderAccountId) {
            this.showToast('Error', 'No Account associated with this Order. Coupon cannot be applied.', 'error');
            this.isLoading = false;
            return;
        }
        if (!this.couponCode) {
            this.showToast('Info', 'Please enter a coupon code.', 'warning');
            console.log('this.couponCode ==>'+this.couponCode);
            this.isLoading = false;
            return;
        }

        try {
            this.isLoading = true;
            this.accountCases = await getAccountCasesWithCoupons({ accountId: this.orderAccountId });

            this.matchedCoupon = null;
            for (const caseRecord of this.accountCases) {
                if (caseRecord.Coupon_Codes__r) {
                    this.matchedCoupon = caseRecord.Coupon_Codes__r.find(
                        c => c.Coupon__c === this.couponCode
                    );
                    if (this.matchedCoupon) break;
                    console.log('this.matchedCoupon =>',this.matchedCoupon);
                }
            }

            if (!this.matchedCoupon) {
                debugger;
                this.showToast('Invalid Coupon', 'Coupon code is invalid.', 'error');
                this.isLoading = false;
                return;
            }

            if (this.matchedCoupon.Status__c === 'Expired') {
                this.showToast('Expired Coupon', 'This coupon code has expired.', 'warning');
                this.isLoading = false;
                return;
            }

            if (this.matchedCoupon.Status__c === 'Redeemed') {
                this.showToast('Redeemed Coupon', 'This coupon code has already been redeemed.', 'warning');
                this.isLoading = false;
                return;
            }
            if (this.matchedCoupon.Status__c === 'cancelled') {
                this.showToast('Invalid Coupon', 'This coupon code is cancelled along with order and cannot be used.', 'error');
                this.isLoading = false;
                return;
            }

            const validPrefixes = ['CCGWAC', 'RVAC', 'CCGWRG', 'CCGWGR', 'CCGWVH'];
            const prefix = validPrefixes.find(p => this.couponCode.toUpperCase().startsWith(p));

            if (!prefix) {
                this.showToast('Invalid Prefix', 'Coupon prefix is invalid or unsupported.', 'error');
                this.isLoading = false;
                return;
            }

            if (prefix === 'RVAC') {
                const accountSource = this.accountCases[0]?.Account?.AccountSource;
                if (accountSource !== 'Shopify') {
                    this.showToast('Invalid Coupon', 'This website coupon can only be used for Website Order.', 'error');
                    this.isLoading = false;
                    return;
                }
            }

            this.orderItems = await getOrderItems({ orderId: this.recordId });
            const hasMatchingItem = this.validateOrderItemType(this.orderItems, prefix);

            if (!hasMatchingItem) {
                this.showToast('Not Applicable', 'Coupon cannot be applied to this Order. No matching item types.', 'warning');
                this.isLoading = false;
                return;
            }
            await applyCouponToOrder({
                orderId: this.recordId,
                couponId: this.matchedCoupon.Id,
                couponValue: this.matchedCoupon.Value__c,
                prefix: prefix,
                couponCode: this.matchedCoupon.Coupon__c
            });

            this.showToast('Success', 'Coupon applied successfully!', 'success');
            this.closeModal();
        } catch (err) {
            this.isLoading = false;
            console.error('Error applying coupon:', err);
            this.showToast('Error', 'Invalid Coupon', 'error');
        }
    }


    validateOrderItemType(orderItems, prefix) {
        if (prefix === 'CCGWGR') return true;

        const typeMap = {
            CCGWAC: ['Accessories', 'Parts', 'Road side assistance', 'Extended Warrenty', 'Add-ons'],
            CCGWRG: 'Merchandise',
            CCGWVH: 'Vehicle',
            RVAC: ['Accessories', 'Parts']
        };

        const expectedType = typeMap[prefix];

        if (!expectedType) return false;

        if (Array.isArray(expectedType)) {
            return orderItems.some(item => expectedType.includes(item.Type__c));
        } else {
            return orderItems.some(item => item.Type__c === expectedType);
        }
    }

    closeModal() {
        debugger;
        
        this.trackCount--;
        this.ISShowModel = false;
        console.log('Modal closed immediately');
    }

    dontHaveCoupon() {
    debugger;
    this.trackCount--;
    this.isLoading = true;
    markCustomerHasNoCoupon({ orderId: this.recordId })
            .then(() => {
                this.showToast('Info', 'Marked as no coupon used.', 'info');
                console.log('Customer_Has_No_Coupon__c updated successfully');
                this.ISShowModel = false;
            })
            .catch(error => {
                console.error('Error updating order:', error);
                this.showToast('Info', 'Error marking Customer has no Coupon', 'info');
                this.isLoading = false;
            });
        console.log('Modal closed immediately');
    }

    async checkIfCouponAvailable(accountId) {
        try {
            debugger;
            const cases = await getAccountCasesWithCoupons({ accountId });
            for (const caseRecord of cases) {
                if (caseRecord.Coupon_Codes__r && caseRecord.Coupon_Codes__r.length > 0) {
                    const validCoupon = caseRecord.Coupon_Codes__r.find(c => 
                        c.Status__c !== 'Expired' && 
                        c.Status__c !== 'Redeemed' &&
                        c.Status__c !== 'cancelled'
                    );
                    if (validCoupon) {
                        this.ISShowModel = true;
                        this.trackCount++;
                        return;
                    }
                }
            }
            console.log('No valid coupons found — modal will not be shown.');
        } catch (error) {
            console.error('Error checking coupon availability:', error);
        }
    }


    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

}