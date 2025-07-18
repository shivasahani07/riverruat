import { LightningElement, api } from 'lwc';

export default class CaseCategoryInlinePicklist extends LightningElement {
    @api typeAttributes;

    handleChange(event) {
        const value = event.detail.value;
        const context = event.target.dataset.id;

        this.dispatchEvent(new CustomEvent('cellchange', {
            detail: {
                draftValues: [
                    {
                        Id: context,
                        Case_Category__c: value
                    }
                ]
            },
            bubbles: true,
            composed: true
        }));
    }
}