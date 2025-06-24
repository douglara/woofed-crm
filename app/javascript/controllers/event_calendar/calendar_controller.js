import { Controller } from "stimulus";
import Rails from "@rails/ujs";
import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";
import interactionPlugin from "@fullcalendar/interaction";

export default class extends Controller {
  static values = {
    eventsUrl: String,
  };

  connect() {
    console.log("conectado ao calendario", this.eventsUrlValue);
    let calendarEl = this.element;
    this.calendar = new Calendar(calendarEl, {
      navLinks: true,
      weekNumbers: true,
      nowIndicator: true,
      // themeSystem: "bootstrap",
      events: this.eventsUrlValue,
      editable: true,
      eventDrop: this.handleEventDrop.bind(this),
      // events: [
      //   {
      //     title: "Olá",
      //     start: "2025-06-24T10:00:00",
      //     // end: "2025-06-24T16:00:00",
      //     extendedProps: {
      //       department: "BioChemistry",
      //     },
      //     description: "Lecture",
      //     url: "https://google.com/",
      //     // display: "background",
      //   },
      //   {
      //     title: "Olá 2",
      //     start: "2025-06-24T10:00:00",
      //     // end: "2025-06-24T12:00:00",
      //     extendedProps: {
      //       department: "BioChemistry",
      //     },
      //     description: "Lecture",
      //     url: "https://google.com/",
      //     // display: "background",
      //   },
      // ],
      eventClick: function (info) {
        info.jsEvent.preventDefault();
        if (info.event.url) {
          window.open(info.event.url);
        }
        // console.log("Evento clicado:", info.event);
        // alert(`Você clicou no evento: ${info.event.title}`);
      },
      // navLinkDayClick: function (date, jsEvent) {
      //   console.log("day", date.toISOString());
      //   console.log("coords", jsEvent.pageX, jsEvent.pageY);
      // },
      // navLinkWeekClick: function (weekStart, jsEvent) {
      //   console.log("week start", weekStart.toISOString());
      //   console.log("coords", jsEvent.pageX, jsEvent.pageY);
      // },
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      initialView: "dayGridMonth",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,listWeek",
      },
    });
    this.calendar.render();
  }
  disconnect() {
    this.calendar.destroy();
  }

  async handleEventDrop(info) {
    const event = info.event;
    const { account_id, contact_id, deal_id } = event.extendedProps;
    Rails.ajax({
      url: `/accounts/${account_id}/contacts/${contact_id}/events/${event.id}`,
      type: "PATCH",
      data: new URLSearchParams({
        "event[scheduled_at]": info.event.start.toISOString(),
        deal_id: deal_id,
      }).toString(),
      success: () => {
        console.log("Data atualizada com sucesso");
      },
      error: () => {
        info.revert();
        alert("Erro ao atualizar a data do evento");
      },
    });
  }
}
