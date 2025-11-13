import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AppointmentCalendar extends LightningElement {

    @track dates = [];
    weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    _bookedDates = [];
    selectedDate = null;

    

    currentDate = new Date();
    monthName;
    year;


    isDateBooked(date) {
    return this.bookedDates.includes(date);
    }

    @api 
    set bookedDates(value) {
        if (value) {
            this._bookedDates = value.map(d => d.split('T')[0]); 
            this.generateCalendar();
        }
    }
    get bookedDates() {
        return this._bookedDates;
    }

    connectedCallback() {
        this.generateCalendar();
    }

    generateCalendar() {
        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();

        this.year = year;
        this.monthName = this.currentDate.toLocaleString('default', { month: 'long' });

        let firstDay = new Date(year, month, 1).getDay();
        let totalDays = new Date(year, month + 1, 0).getDate();

        let tempDates = [];

        
        for (let i = 0; i < firstDay; i++) {
            tempDates.push({
                day: '',
                fullDate: '',
                dateKey: `blank-${i}`,
                classList: 'empty'
            });
        }

        
        for (let day = 1; day <= totalDays; day++) {
            let fullDate = `${year}-${String(month + 1).padStart(2,'0')}-${String(day).padStart(2,'0')}`;

            let isBooked = this._bookedDates.includes(fullDate);
            let isSelected = fullDate === this.selectedDate;

            let classList = 'date'; 

            if (isBooked) {
                classList = 'date booked'; 
            } else if (isSelected) {
                classList = 'date selected'; 
            }

            tempDates.push({
                day,
                fullDate,
                dateKey: fullDate,
                classList
            });
        }

        this.dates = tempDates;
    }

    prevMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.generateCalendar();
    }

    nextMonth() {
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.generateCalendar();
    }

    handleDateClick(event) {
        const date = event.target.dataset.date;
        if (!date) return;

        if (this._bookedDates.includes(date)) {
            this.showError('Appointment is already booked');
            return;
        }

        this.selectedDate = date;
        this.generateCalendar();

        this.dispatchEvent(new CustomEvent("dateclick", {
            detail: { selectedDate: date }
        }));
    }

    showError(msg) {
        this.dispatchEvent(new ShowToastEvent({
            title: "Error",
            message: msg,
            variant: "error"
        }));
    }
}