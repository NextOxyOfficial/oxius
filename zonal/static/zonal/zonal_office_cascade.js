/* Division -> City cascade on the Zonal Office admin form.
   Stashes the full city option list once, then rebuilds the select with only
   the chosen division's cities (rebuild, not hide, so it also works if the
   theme restyles selects). */
(function () {
  function init() {
    var divisionEl = document.getElementById("id_division");
    var cityEl = document.getElementById("id_city");
    if (!divisionEl || !cityEl || cityEl.tagName !== "SELECT") return;

    var all = Array.prototype.map.call(cityEl.options, function (o) {
      return {
        value: o.value,
        label: o.text,
        division: o.getAttribute("data-division") || "",
        selected: o.selected,
      };
    });

    function rebuild() {
      var d = divisionEl.value;
      var current = cityEl.value;
      cityEl.innerHTML = "";
      all.forEach(function (o) {
        if (o.value && d && o.division !== d) return; // filtered out
        var opt = document.createElement("option");
        opt.value = o.value;
        opt.text = o.label;
        if (o.division) opt.setAttribute("data-division", o.division);
        cityEl.appendChild(opt);
      });
      // Keep the current selection if it survived the filter, else reset.
      var values = Array.prototype.map.call(cityEl.options, function (o) {
        return o.value;
      });
      cityEl.value = values.indexOf(current) !== -1 ? current : "";
    }

    divisionEl.addEventListener("change", rebuild);
    if (divisionEl.value) rebuild();
  }

  if (document.readyState !== "loading") init();
  else document.addEventListener("DOMContentLoaded", init);
})();
