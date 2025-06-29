/* JavaScript to add data attributes for row coloring based on service_status */

document.addEventListener("DOMContentLoaded", function () {
  // Get the table rows
  var rows = document.querySelectorAll("#result_list tbody tr");

  rows.forEach(function (row) {
    // Find the service_status column (now colored_service_status)
    var statusCell = row.querySelector(".field-colored_service_status");

    if (statusCell) {
      // Look for the span with data-status attribute
      var statusSpan = statusCell.querySelector("span[data-status]");

      if (statusSpan) {
        var statusText = statusSpan.getAttribute("data-status");

        // Add data attribute to the entire row for CSS styling
        row.setAttribute("data-status", statusText);
      }
    }
  });
});
