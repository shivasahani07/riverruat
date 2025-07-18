import LightningDatatable from 'lightning/datatable';
import picklistTemplate from './getCaseCategoryInlinePicklist.html';

export default class GetCaseCategoryInlinePicklist extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: picklistTemplate,
            typeAttributes: ['placeholder', 'options', 'value', 'context'],
            standardCellLayout: true,
            editable: true
        }
    };
}