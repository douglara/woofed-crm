import { Controller } from "@hotwired/stimulus";
import Rails from "@rails/ujs";
import { Calendar } from "@fullcalendar/core";
import dayGridPlugin from "@fullcalendar/daygrid";
import timeGridPlugin from "@fullcalendar/timegrid";
import listPlugin from "@fullcalendar/list";
import interactionPlugin from "@fullcalendar/interaction";
import ptBrLocale from "@fullcalendar/core/locales/pt-br";
import esLocale from "@fullcalendar/core/locales/es";
import enGbLocale from "@fullcalendar/core/locales/en-gb";
import ukLocale from "@fullcalendar/core/locales/uk";

export default class extends Controller {
  static targets = ["calendar"];

  static values = {
    eventsUrl: String,
    language: String,
  };

  connect() {
    this.configureLocaleTexts();
    this.calendar = new Calendar(this.calendarTarget, {
      timeZone: "local",
      navLinks: true,
      allDaySlot: false,
      nowIndicator: true,
      events: this.eventsUrlValue,
      eventTextColor: "#FFFFFF",
      displayEventEnd: false,
      locale: this.language,
      editable: true,
      eventDrop: this.handleEventDrop.bind(this),
      eventClick: function (info) {
        info.jsEvent.preventDefault();
        if (info.event.url) {
          window.location.href = info.event.url;
        }
      },
      views: {
        dayGridMonth: {
          dayMaxEvents: true,
        },
        timeGridWeek: {
          dayMaxEvents: false,
        },
        listWeek: {
          dayMaxEvents: false,
        },
      },
      plugins: [dayGridPlugin, timeGridPlugin, listPlugin, interactionPlugin],
      initialView: "listWeek",
      headerToolbar: {
        right: "prev,next today",
        center: "title",
        left: "listWeek timeGridWeek dayGridMonth",
      },

      loading: function (loading) {
        if (loading) {
          this.calendarTarget.classList.add("hidden");
        } else {
          this.calendarTarget.classList.remove("hidden");
        }
      }.bind(this),
    });

    this.calendar.render();
  }

  disconnect() {
    this.calendar.destroy();
  }

  configureLocaleTexts() {
    ptBrLocale.noEventsText = "Nenhuma atividade para mostrar";
    enGbLocale.noEventsText = "No activities to display";
    esLocale.noEventsText = "No hay actividades para mostrar";
    ukLocale.noEventsText = "Немає активностей для відображення";
    if (ukLocale.buttonText) {
      ukLocale.buttonText.list = "Список";
      ukLocale.buttonText.next = "Наступний";
      ukLocale.buttonText.prev = "Попередній";
      ukLocale.buttonText.today = "Сьогодні";
    }
  }

  get language() {
    const languageMap = {
      "pt-br": ptBrLocale,
      es: esLocale,
      en: enGbLocale,
      uk: ukLocale,
    };

    const lang = this.languageValue?.toLowerCase() || "en";
    return languageMap[lang] || enGbLocale;
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
      error: () => {
        info.revert();
        alert("Erro to update event!");
      },
    });
  }
}
