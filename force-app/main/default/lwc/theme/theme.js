import { LightningElement, track } from 'lwc';

const VIN_LENGTH = 17;
const VIN_PATTERN = 'CNCCCCCNCCNNNNNNN'; // // VIN Pattern: C = Character, N = Number


export default class VinInput extends LightningElement {
    /*
    vinLength = Array.from({ length: VIN_LENGTH }, (_, i) => i + 1);
    @track vinChars = Array(VIN_LENGTH).fill('');
    vinValue = '';
    */
    vinLength = [];
    vinChars = [];
    vinValue = '';

    connectedCallback() {
        for (let i = 1; i <= VIN_LENGTH; i++) {
            this.vinLength.push(i);
        }
        console.log('this.vinLength : ' + this.vinLength);

        for (let i = 0; i < VIN_LENGTH; i++) {
            this.vinChars.push('');
        }
        console.log('this.vinChars : ' + this.vinChars);
    }

    // Helper: return regex rule for position
    getRule(index) {
        const ruleMap = {
            'C': /^[A-Za-z]$/, // Character
            'N': /^[0-9]$/     // Number
        };
        console.log(JSON.stringify(ruleMap[VIN_PATTERN[index]]));
        return ruleMap[VIN_PATTERN[index]];
    }

    /*     handleKeyPress(event) {
            const index = parseInt(event.target.dataset.index, 10);
            console.log('index : ' + index);
            const char = event.key;
            console.log('char : ' + char);
    
            const rule = this.getRule(index);
            console.log('rule : ' + rule);
            if (rule && !rule.test(char)) {
                event.preventDefault();
            }
        }
     */
    handleKeyPress(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const char = event.key;
        console.log('char : ' + char);

        // Handle Backspace
        if (char === 'Backspace') {
            this.vinChars[index] = '';   // Clear the current box

            // Optional: move focus back to previous box if not first
            if (index > 0) {
                const prevInput = this.template.querySelector(
                    `lightning-input[data-index="${index - 1}"]`
                );
                if (prevInput) {
                    prevInput.focus();
                }
            }
            return; // Skip regex validation
        }

        // Validation for allowed characters
        const rule = this.getRule(index);
        if (rule && !rule.test(char)) {
            event.preventDefault();
        }
    }

    handleChange(event) {
        const index = parseInt(event.target.dataset.index, 10);
        const value = event.target.value.toUpperCase();

        this.vinChars[index] = value;

        // Auto-move to next box
        if (value && index < VIN_LENGTH - 1) {
            const nextInput = this.template.querySelector(
                `lightning-input[data-index="${index + 1}"]`
            );
            if (nextInput) {
                nextInput.focus();
            }
        }
    }

    handleSubmit() {
        this.vinValue = this.vinChars.join('');
    }
}