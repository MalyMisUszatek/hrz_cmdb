
// ---- Tooltip init for CF field descriptions (added 2026-05-12) ----
HrzCmdb.initTooltips = function() {
  document.querySelectorAll('.hrzcm-field-tooltip').forEach(function(el) {
    el.setAttribute('title', el.getAttribute('title'));
  });
};
document.addEventListener('DOMContentLoaded', function() {
  HrzCmdb.initTooltips();
});

// ---- Field visibility toggle (CI class admin panel) ----
HrzCmdb.updateFieldVisibility = function(checkbox) {
  var field = checkbox.getAttribute('data-field');
  var visible = checkbox.checked;
  // Live preview: toggle fields in currently open CI form if present
  var ciForm = document.querySelector('.ci-detail-form, #ci-detail-form');
  if (ciForm && field) {
    var map = {
      'show_bproducer': 'bproducer',
      'show_bmodel':    'bmodel',
      'show_btagserial':'btagserial',
      'show_burldoc':   'burldoc'
    };
    var fieldName = map[field];
    if (fieldName) {
      var el = ciForm.querySelector('[name="ci[' + fieldName + ']"]');
      if (el) {
        var wrapper = el.closest('.form-group');
        if (wrapper) wrapper.style.display = visible ? '' : 'none';
      }
    }
  }
};
// ---- end field visibility ----
