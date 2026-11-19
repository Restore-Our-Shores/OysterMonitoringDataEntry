(function () {
  "use strict";
  document.addEventListener("click", async function (event) {
    const button = event.target.closest(".workbook-save-as");
    if (!button) return;
    const card = button.parentElement.parentElement;
    const status = card.querySelector(".workbook-save-status");
    if (typeof window.showSaveFilePicker !== "function") {
      status.textContent = "Save location selection is unavailable in this browser. Use Download event workbook and your browser's normal save controls.";
      return;
    }
    const link = card.querySelector("a.workbook-download");
    if (!link || !link.getAttribute("href") || link.getAttribute("href") === "#") {
      status.textContent = "The workbook is still preparing. Please try again in a moment.";
      return;
    }
    const mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    button.disabled = true;
    let stream;
    try {
      const handle = await window.showSaveFilePicker({suggestedName: link.dataset.filename,
        types: [{description: "Excel workbook", accept: {[mime]: [".xlsx"]}}]});
      status.textContent = "Preparing your event workbook...";
      const response = await fetch(link.href, {credentials: "same-origin"});
      if (!response.ok || !(response.headers.get("content-type") || "").startsWith(mime)) {
        throw new Error("Workbook download failed");
      }
      const contents = await response.blob();
      stream = await handle.createWritable();
      await stream.write(contents);
      await stream.close();
      stream = null;
      status.textContent = "Event workbook saved to your selected location.";
    } catch (error) {
      if (stream && stream.abort) { try { await stream.abort(); } catch (_) {} }
      status.textContent = error.name === "AbortError" ? "Save canceled. Your finalized event is still available." :
        "The workbook could not be saved. Keep this event open and retry, or use Download event workbook.";
    } finally { button.disabled = false; }
  });
})();
