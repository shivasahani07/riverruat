import { LightningElement, api } from 'lwc';

export default class Loader extends LightningElement {
    @api loading = false;
    @api message='Processing... Please wait';
}