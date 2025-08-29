import { LightningElement, track, wire } from 'lwc';
import MY_RANK from "@salesforce/resourceUrl/MyRank";
import HIKER from "@salesforce/resourceUrl/Hiker";
import ALL_STAR_RANGER from "@salesforce/resourceUrl/AllStarRanger";
import FIVE_STAR_RANGER from "@salesforce/resourceUrl/FiveStarRanger";
import FOUR_STAR_RANGER from "@salesforce/resourceUrl/FourStarRanger";
import TRIPLE_STAR_RANGER from "@salesforce/resourceUrl/TripleStarRanger";
import DOUBLE_STAR_RANGER from "@salesforce/resourceUrl/DoubleStarRanger";
import RANGER from "@salesforce/resourceUrl/Ranger";
import FIRST_RANK from "@salesforce/resourceUrl/FirstRank";
import SECOND_RANK from "@salesforce/resourceUrl/SecondRank";
import THIRD_RANK from "@salesforce/resourceUrl/ThirdRank";
import getEmployeeDetails from '@salesforce/apex/leadershipDashboardController.getEmployeeDetails';
import getCurrentUserDetails from '@salesforce/apex/leadershipDashboardController.getCurrentUserDetails';

export default class LeadershipDashboardCmp extends LightningElement {

    myrank = MY_RANK;
    hiker = HIKER;
    allstarranger = ALL_STAR_RANGER;
    fivestarranger = FIVE_STAR_RANGER;
    fourstarranger = FOUR_STAR_RANGER;
    triplestarranger = TRIPLE_STAR_RANGER;
    doubestarranger = DOUBLE_STAR_RANGER
    ranger = RANGER;
    firstrank = FIRST_RANK;
    secondrank = SECOND_RANK;
    thirdrank = THIRD_RANK;

    @track sortByValue = 'Monthly';
    @track employeeList;
    @track showQuizSummary = false;
    @track myPoints;
    @track showLevelPopup = false;
    @track badges;
    @track points;
    @track levels;
    @track levelImage;

    openLevelImage(event) {
        const points = event.target.dataset.level;
        console.log(points);
        const parts = points.split('/');
        const lastWord = parts[parts.length - 1];
        console.log(lastWord);
        const spacedString = lastWord.replace(/([A-Z])/g, ' $1').trim();
        const upperCaseString = spacedString.toUpperCase();
        this.levels = upperCaseString;
        const badgesWithText = event.target.dataset.badges;
        this.badges = badgesWithText.replace('Badges', '');
        const pointsWithoutText = event.target.dataset.points;
        this.points = pointsWithoutText.replace('Points', '');
        this.levelImage = this.formatLevels(this.points);
        this.showLevelPopup = true;
    }

    hideModalBox() {
        this.showLevelPopup = false;
    }

    @wire(getEmployeeDetails)
    wiredOppDetails({ data, error }) {
        debugger;
        if (data) {
            this.employeeList = data.map((emp, index) => ({
                ...emp,
                Index: index,
                Points_custom: this.formatPoints(emp.Points__c),
                Badges__c: emp.Badges__c + ' Badges',
                Levels: this.formatLevels(emp.Points__c),
                indexCount: this.formatIndexCount(index),
                formattedIndex: this.formatIndex(index),
                rankCss: this.formatCss(index)
            }));
            console.log('employeeList==>' + this.employeeList);
            this.getCurentEmployee();
        } else if (error) {
            console.error('Error fetching details', error);
        }
    }

    formatCss(index) {
        if (index == 0) {
            return 'firstRank';
        } else if (index == 1) {
            return 'secondRank';
        } else if (index == 2) {
            return 'thirdRank';
        } else {
            return 'normalIndex';
        }
    }

    formatIndexCount(index) {
        if (index >= 0 && index <= 2) {
            return true;
        } else {
            return false;
        }
    }

    formatIndex(index) {
        if (index == 0) {
            return this.firstrank;
        } else if (index == 1) {
            return this.secondrank;
        } else if (index == 2) {
            return this.thirdrank;
        } else {
            return index + 1;
        }
    }

    @track currentEmployee;
    @track myRankIndex;
    getCurentEmployee() {
        debugger;
        getCurrentUserDetails()
            .then(result => {
                this.currentEmployee = result;
                this.myPoints = result.Points__c;
                const currentIndex = this.employeeList.findIndex(emp => emp.Employee_Name__c === this.currentEmployee.Employee_Name__c);
                console.log("Index of current employee:", currentIndex);
                this.myRankIndex = currentIndex+1;
            })
            .catch(error => {
                console.error('Error:', error);
            });
    }

    formatLevels(points) {
        if (points >= 300000) {
            return this.allstarranger;
        } else if (points >= 250000) {
            return this.fivestarranger;
        } else if (points >= 200000) {
            return this.fourstarranger;
        } else if (points >= 150000) {
            return this.triplestarranger;
        } else if (points >= 100000) {
            return this.doubestarranger;
        } else {
            return this.ranger;
        }
    }

    formatPoints(points) {
        if (points >= 300000) {
            return '300K+ Points';
        } else if (points < 300000 && points >= 250000) {
            return '250K+ Points';
        } else if (points < 250000 && points >= 200000) {
            return '200K+ Points';
        } else if (points < 200000 && points >= 150000) {
            return '150K+ Points';
        } else if (points < 150000 && points >= 100000) {
            return '100K+ Points';
        } else {
            return points + ' Points';
        }
    }

    get sortByOptions() {
        return [
            { label: 'Monthly', value: 'Monthly' },
            { label: 'Quarterly', value: 'Quarterly' },
            { label: 'Yearly', value: 'Yearly' },
        ];
    }

    handleChangeSortby(event) {
        this.sortByValue = event.detail.value;
    }

    goToQuizSummary() {
        this.showQuizSummary = true;
    }
}