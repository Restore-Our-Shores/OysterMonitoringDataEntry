(function () {
  "use strict";
  const key = "rosoyster.draft.v1:" + window.location.pathname;
  let locked = false;
  function lockForm(value) {
    locked = value;
    document.querySelectorAll("input,select,textarea,button").forEach(function (el) {
      if (/^(event|visual|measured|structural)-/.test(el.id)) {
        el.disabled = value;
        if (el.selectize) value ? el.selectize.disable() : el.selectize.enable();
      }
    });
  }
  $(document).on("shiny:connected", function () {
    let saved = "";
    try { saved = localStorage.getItem(key) || ""; }
    catch (_) { Shiny.setInputValue("draft_storage_error", Date.now(), {priority: "event"}); }
    Shiny.setInputValue("draft_found", {text: saved, nonce: Date.now()}, {priority: "event"});
  });
  Shiny.addCustomMessageHandler("draft-save", function (message) {
    try { localStorage.setItem(key, message.text); }
    catch (_) { Shiny.setInputValue("draft_storage_error", Date.now(), {priority: "event"}); }
  });
  Shiny.addCustomMessageHandler("draft-clear", function (message) {
    try { localStorage.removeItem(key); } catch (_) {}
  });
  Shiny.addCustomMessageHandler("submission-lock", lockForm);
  Shiny.addCustomMessageHandler("draft-restore-inputs", function (values) {
    function restore(id, value) {
      const el = document.getElementById(id);
      if (!el) return false;
      if (el.selectize) el.selectize.setValue(value);
      else if (el.type === "checkbox") { el.checked = !!value; $(el).trigger("change"); }
      else if ($(el).hasClass("shiny-date-input")) {
        $(el).find("input").bsDatepicker("update", value);
        $(el).trigger("change");
      } else { el.value = value == null ? "" : value; $(el).trigger("change"); }
      // Let each Shiny input binding encode its own value and type. Sending a
      // second untyped value here can turn a blank numeric field into NULL.
      return true;
    }
    // Restore structure selection first so its dynamic measurement controls exist.
    if (Object.hasOwn(values, "structural-structure_type")) restore("structural-structure_type", values["structural-structure_type"]);
    Object.keys(values).filter(id => !id.startsWith("structural-depth_")).forEach(id => restore(id, values[id]));
    let attempts = 0;
    const timer = setInterval(function () {
      const ids = Object.keys(values).filter(id => id.startsWith("structural-depth_"));
      ids.forEach(id => restore(id, values[id]));
      lockForm(locked);
      if (++attempts >= 5) clearInterval(timer);
    }, 200);
  });
  window.addEventListener("beforeunload", function (event) {
    if (document.querySelector(".shiny-disconnected-overlay")) {
      event.preventDefault(); event.returnValue = "";
    }
  });
})();
