import { LightningElement, track, api } from 'lwc';

export default class DynamicWizard extends LightningElement {
    @track currentIndex = 0;
    @api components = [];
    @api initialData = {};
    @api validationRequired = false;
    
    dataStore = {};
    nextDisabled = false;
    finishDisabled = false;

    // Getters for template computed values
    get componentsLength() {
        debugger;
        return this.components.length;
    }
    
    get currentStepNumber() {
         debugger;
        return this.currentIndex + 1;
    }
    
    get progressValue() {
         debugger;
        return Math.round((this.currentIndex / this.components.length) * 100);
    }
    
    get progressStyle() {
         debugger;
        return `width: ${this.progressValue}%`;
    }
    
    get currentStepName() {
         debugger;
        return this.currentComponent?.name || '';
    }
    
    get currentComponent() {
         debugger;
        return this.components[this.currentIndex] || {};
    }
    
    get currentComponentLabel() {
         debugger;
        const current = this.currentComponent;
        return current.label || current.name || '';
    }
    
    get cmpLabel() {
         debugger;
        // This would need to be handled differently as it's in a loop
        // We'll need to create a separate component for progress steps
        // or handle this in the connectedCallback
        return '';
    }
    
    get isFirst() {
         debugger;
        return this.currentIndex === 0;
    }
    
    get isLast() {
         debugger;
        return this.currentIndex === this.components.length - 1;
    }
    
    get stepIndicatorTitle() {
         debugger;
        // This would need index context which isn't available in a simple getter
        // We'll need to handle this in a different way
        return 'Go to step';
    }
    
    get stepIndicatorAltText() {
         debugger;
        // Same issue as above
        return 'Step';
    }
    
    get stepIndicatorClass() {
         debugger;
        // Same issue as above
        return '';
    }

    connectedCallback() {
        debugger;
        this.loadComponents(this.components);
    }

    async loadComponents(componentConfigs = []) {
        debugger;
        let componentList = JSON.parse(componentConfigs.replace(/'/g, '"'));
        try {
            const loadPromises = componentList.map(async (config) => {
                const name = typeof config === 'string' ? config : config.name;
                try {
                    const { default: ctor } = await import(`c/${name}`);
                    return {
                        name,
                        ctor,
                        label: config.label || name,
                        props: config.props || {}
                    };
                } catch (error) {
                    console.error(`Error loading component ${name}:`, error);
                    throw error;
                }
            });

            this.components = await Promise.all(loadPromises);
            this.currentIndex = 0;
            this.setCurrentComponent();
        } catch (error) {
            console.error('Error loading components', error);
            this.dispatchEvent(new CustomEvent('error', { 
                detail: { message: 'Failed to load wizard components', error } 
            }));
        }
    }

    setCurrentComponent() {
         debugger;
        const current = this.currentComponent;
        if (!current || !current.ctor) return;
        
        this.childProps = {
            ...current.props,
            wizardData: this.dataStore,
            stepData: this.dataStore[current.name] || {},
            stepIndex: this.currentIndex,
            isFirstStep: this.isFirst,
            isLastStep: this.isLast
        };
        
        this.componentConstructor = current.ctor;
        this.updateButtonStates();
    }

    updateButtonStates() {
         debugger;
        if (this.validationRequired) {
            const cmp = this.template.querySelector('[data-id="currentStepComponent"]');
            if (cmp && typeof cmp.isValid === 'function') {
                const isValid = cmp.isValid();
                this.nextDisabled = !isValid;
                this.finishDisabled = !isValid;
            }
        }
    }

    handleStepChange(event) {
         debugger;
        const { type, data } = event.detail;
        
        switch (type) {
            case 'dataChange':
                this.saveCurrentData(data);
                break;
            case 'validationChange':
                if (this.validationRequired) {
                    const isValid = event.detail.isValid;
                    this.nextDisabled = !isValid;
                    this.finishDisabled = !isValid;
                }
                break;
            case 'navigateNext':
                if (!this.nextDisabled) this.handleNext();
                break;
            case 'navigatePrevious':
                this.handlePrevious();
                break;
            default:
                console.warn('Unknown step change type:', type);
        }
    }

    handleNext() {
         debugger;
        if (this.validationRequired && this.nextDisabled) return;
        
        this.saveCurrentData();
        if (!this.isLast) {
            this.currentIndex++;
            this.setCurrentComponent();
            this.dispatchEvent(new CustomEvent('stepchange', {
                detail: { previousIndex: this.currentIndex - 1, newIndex: this.currentIndex }
            }));
        }
    }

    handlePrevious() {
         debugger;
        this.saveCurrentData();
        if (!this.isFirst) {
            this.currentIndex--;
            this.setCurrentComponent();
            this.dispatchEvent(new CustomEvent('stepchange', {
                detail: { previousIndex: this.currentIndex + 1, newIndex: this.currentIndex }
            }));
        }
    }

    handleFinish() {
         debugger;
        if (this.validationRequired && this.finishDisabled) return;
        
        this.saveCurrentData();
        this.dispatchEvent(new CustomEvent('finish', { 
            detail: { data: this.dataStore, complete: true } 
        }));
    }
    
    handleSave() {
         debugger;
        this.saveCurrentData();
        this.dispatchEvent(new CustomEvent('save', { 
            detail: { data: this.dataStore } 
        }));
    }

    saveCurrentData(providedData) {
         debugger;
        const cmp = this.template.querySelector('[data-id="currentStepComponent"]');
        let stepData = providedData;
        
        if (!stepData && cmp && cmp.getData) {
            stepData = cmp.getData();
        }
        
        if (stepData) {
            this.dataStore[this.currentComponent.name] = {
                ...this.dataStore[this.currentComponent.name],
                ...stepData
            };
        }
    }

    handleStepIndicatorClick(event) {
         debugger;
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this.navigateToStep(index);
    }
    
    navigateToStep(index) {
         debugger;
        if (index >= 0 && index < this.components.length) {
            this.saveCurrentData();
            this.currentIndex = index;
            this.setCurrentComponent();
        }
    }
}