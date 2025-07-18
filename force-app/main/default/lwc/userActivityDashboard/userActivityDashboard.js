import { LightningElement, track } from 'lwc';
import getAllUserTrack from '@salesforce/apex/UserTrackingcontroller.getAllUserTrack';
import userRecordToUpdate from '@salesforce/apex/UserTrackingcontroller.userRecordToUpdate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class UserActivityDashboard extends LightningElement {
    @track showSpinner = false;
    @track searchKey = '';
    @track selectedDate = '';
    activeSections = ['A', 'B', 'C'];
    @track users = [];
    @track allUsers = [];

    connectedCallback() {
        debugger;
        getAllUserTrack({ oldDate: null })
            .then(result => {
                if (result) {
                    this.allUsers = result;
                    this.users = result;
                }
            })
            .catch(error => {
                console.error('Error in fetching user data', JSON.stringify(error));
            });
    }
    
    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
    
        if (this.searchKey) {
            this.users = {
                allUsers: this.allUsers.allUsers.filter(user =>
                    user.Name.toLowerCase().includes(this.searchKey)
                ),
                allUserscheckedIn: this.allUsers.allUserscheckedIn.filter(user =>
                    user.memberName.toLowerCase().includes(this.searchKey)
                ),
                allUserscheckedOut: this.allUsers.allUserscheckedOut.filter(user =>
                    user.memberName.toLowerCase().includes(this.searchKey)
                )
            };
        } else {
            this.users = this.allUsers;
        }
    }
    
    handleClick(event) {
        debugger;
        this.showSpinner = true;
        const userId = event.target.dataset.id;
        const actionType = event.target.dataset.action;
        //const currentTime = new Date().toLocaleString();

        userRecordToUpdate({ userId: userId, actionType: actionType })
            .then(result => {
                if (result === 'User record updated successfully') {
                    const evt = new ShowToastEvent({
                        title: 'Toast Success',
                        message: 'User record updated successfully',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);

                    getAllUserTrack({ oldDate: null })
                        .then(result => {
                            if (result) {
                                this.users = result;
                            }
                        })
                        .catch(error => {
                            console.error('Error in fetching user data', JSON.stringify(error));
                        });
                }
                if (result === 'No user record found for the given userId') {
                    const evt = new ShowToastEvent({
                        title: 'Toast Error',
                        message: 'No user record found for the given userId',
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(evt);
                }
            })
            .catch(error => {
                console.error('Error in fetching user data', JSON.stringify(error));
            });

        this.showSpinner = false;
    }

    

    handleDateChange(event) {
        debugger;
        this.selectedDate = event.target.value;
        getAllUserTrack({ oldDate: this.selectedDate })
            .then(result => {
                if (result) {
                    this.users = result;
                }
            })
            .catch(error => {
                console.error('Error in fetching user data', JSON.stringify(error));
            });
    }

}