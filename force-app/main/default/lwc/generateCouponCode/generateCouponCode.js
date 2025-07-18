import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getValidCouponCodes from '@salesforce/apex/CouponCodeController.getValidCouponCodes';
import createCouponCode from '@salesforce/apex/CouponCodeController.createCouponCode';
import getCaseInfo from '@salesforce/apex/CouponCodeController.getCaseInfo';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateCouponCode extends LightningElement {
    @api recordId;
    isLoading = true;

    connectedCallback() {
        debugger;
        const url = window.location.href.toString();
        const queryParams = url.split("&");
        const recordIdParam = queryParams.find(param => param.includes("recordId"));
        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");
            if (recordIdKeyValue.length === 2) {
                const recordId = recordIdKeyValue[1];
                this.recordId = recordId;
            } else {
                console.error("Invalid recordId parameter format");
            }
        } else {
            console.error("recordId parameter not found in the URL");
        }
        if (this.recordId == undefined || this.recordId == null) {
            if (this.recordId == undefined) {
                const url = window.location.href;
                const match = url.match(/\/Case\/([^/]+)/);
                if (match) {
                    this.recordId = match[1];
                    console.log('Record Id:', this.recordId);
                }
            }
            this.recordId = this.recordId;
        }
        this.generateCoupon();
    }

    generateCouponCode(length) {
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += characters.charAt(Math.floor(Math.random() * characters.length));
        }
        return result;
    }

    async generateCoupon() {
        try {
            console.debug('Auto-generating coupon for Case Id: ' + this.recordId);

            const [existingCodes, caseInfo] = await Promise.all([
                getValidCouponCodes(),
                getCaseInfo({ caseId: this.recordId })
            ]);
            const couponFor = caseInfo.couponFor;
            const couponValue = Math.round(caseInfo.couponValue);
            const accountSource = caseInfo.accountSource;
            console.debug('Account Source: ' + accountSource);

            

            let prefix = '';
                switch (couponFor) {
                    case 'Accessories':
                        prefix = 'CCGWAC';
                        break;
                    case 'Merchandise':
                        prefix = 'CCGWRG';
                        break;
                    case 'General':
                        prefix = 'CCGWGR';
                        break;
                    case 'Website':
                        prefix = 'RVAC';
                        break;
                    case 'Vehicle':
                        prefix = 'CCGWVH';
                        break;
                    default:
                        throw new Error(`Unsupported Coupon_For__c value: ${couponFor}`);
                }

            let couponCode;
            let tries = 0;

            do {
                const randomCode = this.generateCouponCode(6); 
                couponCode = `${prefix}${couponValue}${randomCode}`;;
                tries++;
                if (tries > 10) {
                    throw new Error('Failed to generate a unique coupon code after 10 attempts.');
                }
            } while (existingCodes.includes(couponCode));

            await createCouponCode({ caseId: this.recordId, couponCode });

            this.showToast('Success', `Coupon code "${couponCode}" generated successfully!`, 'success');
        } catch (error) {
            console.error('Error generating coupon:', error);
            this.showToast('Error', error.body?.message || error.message || 'Failed to generate coupon', 'error');
            this.dispatchEvent(new CloseActionScreenEvent());
        } finally {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}