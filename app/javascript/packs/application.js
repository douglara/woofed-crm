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
import { initFlowbite } from 'flowbite'
import "flowbite/dist/flowbite.turbo.js";


const load_stisla_scripts = require('./stisla_scripts');

$(document).on("turbo:load", () => {
  initFlowbite();
  lucide.createIcons();
  load_stisla_scripts();
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

$(document).on("turbo:frame-load", function (e) {
  initFlowbite();
  lucide.createIcons();
  load_stisla_scripts();
})

$(document).on("turbo:render", function (e) {
  initFlowbite();
  lucide.createIcons();
  load_stisla_scripts();
})
