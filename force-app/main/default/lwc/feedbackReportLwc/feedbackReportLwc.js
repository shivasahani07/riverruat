import { LightningElement, wire, track } from 'lwc';
import getFeedbackReport from '@salesforce/apex/FeedbackReportController.getFeedbackReport';
import getFeedbackReportCSV from '@salesforce/apex/FeedbackReportController.getFeedbackReportCSV';

export default class FeedbackReportLwc extends LightningElement {
    @track reportData = [];
    @track columns = [];

    @wire(getFeedbackReport)
    wiredReport({ data, error }) {
        if (data) {
            this.reportData = data;

            if (data.length > 0) {
                const standardFields = [
                    'feedbackName',
                    'feedbackId',
                    'status',
                    'serviceCenter',
                    'city',
                    'workOrderNumber',
                    'jobType',
                    'serviceAdvisor'
                ];

                
                let dynamicColumns = Object.keys(data[0])
                    .filter(key => !standardFields.includes(key))
                    .map(key => ({ label: key, fieldName: key }));

                
                this.columns = [
                    { label: 'Feedback Name', fieldName: 'feedbackName' },
                    { label: 'Feedback ID', fieldName: 'feedbackId' },
                    { label: 'Status', fieldName: 'status' },
                    { label: 'Service Center', fieldName: 'serviceCenter' },
                    { label: 'City', fieldName: 'city' },
                    { label: 'Work Order', fieldName: 'workOrderNumber' },
                    { label: 'Job Type', fieldName: 'jobType' },
                    { label: 'Service Advisor', fieldName: 'serviceAdvisor' },
                    ...dynamicColumns
                ];
            }

        } else if (error) {
            console.error('Error fetching feedback report:', error);
        }
    }
    async handleDownload() {
    debugger;
    try {
        const base64Data = await getFeedbackReportCSV();

        const downloadLink = document.createElement('a');
        downloadLink.href = 'data:text/csv;base64,' + base64Data;
        downloadLink.download = 'Feedback_Report.csv';

       
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

    } catch (error) {
        console.error('Error downloading CSV:', JSON.stringify(error));
    }
}

}