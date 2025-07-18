import { LightningElement, track, wire, api } from 'lwc';
import getComponentMapping from '@salesforce/apex/DynamicComponentService.getComponentMapping';
import runDynamicQuery from '@salesforce/apex/DynamicComponentService.runDynamicQuery';
export default class DynamicFormHandlerlwc extends LightningElement {

    @track componentConstructor = null;
    @track childProps = {};
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';
    @track childProps = {

    }

    componentName;
    inputValue;
    queryCondition;

    connectedCallback() {
        debugger;
        const urlParams = this.getAllUrlParams(window.location.href);
        console.log('url object---', JSON.stringify(urlParams, null, '\t'));

        this.componentName = urlParams.formtype;
        this.inputValue = urlParams.input;

        if (this.componentName) {
            this.getDynamicFormDetails();
        } else {
            console.warn('formtype is missing in the URL');
        }
    }

    loadComponent(componentName) {
         debugger;
        import(`c/${componentName}`)
            .then(({ default: ctor }) => {
                this.componentConstructor = ctor;
                this.isLoading = false;
            })
            .catch((err) => {
                this.hasError = true;
                this.errorMessage = `Component '${componentName}' could not be loaded.`;
                this.isLoading = false;
                console.error('Error importing component', err);
            });
    }

    getAllUrlParams(url) {
        debugger;
        var queryString = '';
        var hashString = '';
        var obj = {};

        if (url) {
            const parts = url.split('?');
            queryString = parts[1] ? parts[1].split('#')[0] : '';
            hashString = url.split('#')[1] || '';
        } else {
            queryString = window.location.search.slice(1);
            hashString = window.location.hash.slice(1);
        }

        const fullParamString = [queryString, hashString].filter(Boolean).join('&');

        if (fullParamString) {
            var arr = fullParamString.split('&');

            for (var i = 0; i < arr.length; i++) {
                var a = arr[i].split('=');
                var paramName = decodeURIComponent(a[0]);
                var paramValue = typeof (a[1]) === 'undefined' ? true : decodeURIComponent(a[1]);

                if (paramName.match(/\[(\d+)?\]$/)) {
                    var key = paramName.replace(/\[(\d+)?\]/, '');
                    if (!obj[key]) obj[key] = [];

                    if (paramName.match(/\[\d+\]$/)) {
                        var index = /\[(\d+)\]/.exec(paramName)[1];
                        obj[key][index] = paramValue;
                    } else {
                        obj[key].push(paramValue);
                    }
                } else {
                    if (!obj[paramName]) {
                        obj[paramName] = paramValue;
                    } else if (typeof obj[paramName] === 'string') {
                        obj[paramName] = [obj[paramName]];
                        obj[paramName].push(paramValue);
                    } else {
                        obj[paramName].push(paramValue);
                    }
                }
            }
        }

        if (obj['sessionId']) {
            console.log('✅ sessionId is present:', obj['sessionId']);
        } else {
            console.warn('⚠️ sessionId not found in the URL.');
        }

        console.log('Parsed Parameters Object:', obj);
        return obj;
    }

    getDynamicFormDetails() {
        debugger;
        // Use formtype as key or whatever key you want
        getComponentMapping({ key: this.componentName })
            .then((mapping) => {
                this.componentName = mapping.Component_Name__c;
                this.queryCondition = mapping.Query_Condition__c;
                // Replace placeholder like {input} in SOQL condition with actual inputValue
                const finalQuery = this.queryCondition.replace(':input', `'${this.inputValue}'`);
                return runDynamicQuery({ soql: finalQuery });
            })
            .then((result) => {
                this.childProps = { data: result };
                this.loadComponent(this.componentName);
                this.isLoading = false;
            })
            .catch((err) => {
                this.hasError = true;
                this.errorMessage = 'Error: ' + err.body?.message || err.message || err;
                this.isLoading = false;
            });
    }
}