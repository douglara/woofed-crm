// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import jquery from "jquery";
window.jQuery = jquery;
window.$ = jquery;
import Rails from "@rails/ujs";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import "channels";
import "controllers";
import lucide from "lucide/dist/umd/lucide";

Rails.start();
ActiveStorage.start();
require("trix");
require("@rails/actiontext");
require("@nathanvda/cocoon");
require("bootstrap-daterangepicker/daterangepicker");
import "flowbite/dist/flowbite.turbo.js";

$(document).on("turbo:load", () => {
  initLibraries();
});
//

// $(document).on("turbo:frame-load", function (e) {
//   lucide.createIcons();
//   initDismisses();
//   initDropdowns();
// })

$(document).on("turbo:render", function (e) {
  initLibraries();
});

$(document).on("turbo:frame-render", function (e) {
  initLibraries();
});

// addEventListener("turbo:before-stream-render", (event) => {
//   const originalRender = event.detail.render;

//   event.detail.render = function (streamElement) {
//     originalRender(streamElement);
//     initLibraries();
//   };
// });

function initLibraries() {
  initFlowbite();
  lucide.createIcons();
  // Daterangepicker
  if (jQuery().daterangepicker) {
    if ($(".datetimepicker").length) {
      $(".datetimepicker").daterangepicker({
        locale: { format: "YYYY-MM-DD HH:mm" },
        singleDatePicker: true,
        timePicker: true,
        timePicker24Hour: true,
      });
    }
  }
}
