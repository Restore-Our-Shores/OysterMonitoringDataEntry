(function () {
  "use strict";
  Shiny.addCustomMessageHandler("submission-lock", function (locked) {
    document.querySelectorAll("input,select,textarea,button").forEach(function (element) {
      if (/^(event|visual|measured|structural)-/.test(element.id)) {
        element.disabled = locked;
        if (element.selectize) locked ? element.selectize.disable() : element.selectize.enable();
      }
    });
  });
})();
