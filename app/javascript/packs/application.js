// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import "controllers"
import lucide from "lucide/dist/umd/lucide"

Rails.start()
ActiveStorage.start()
require("trix")
require("@rails/actiontext")
require("@stisla/node_modules/popper.js/dist/umd/popper.min.js")
require("@stisla/node_modules/bootstrap/dist/js/bootstrap")
require("@nathanvda/cocoon")
require("./stisla_scripts")

$(document).on("turbo:load", () => {
  lucide.createIcons();
  // Daterangepicker
  if(jQuery().daterangepicker) {
    if($(".datetimepicker").length) {
      $('.datetimepicker').daterangepicker({
        locale: {format: 'YYYY-MM-DD HH:mm'},
        singleDatePicker: true,
        timePicker: true,
        timePicker24Hour: true,
      });
    }
  }
})