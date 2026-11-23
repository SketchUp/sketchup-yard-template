(function() {

var localStorage = {}, sessionStorage = {};
try { localStorage = window.localStorage; } catch (e) { }
try { sessionStorage = window.sessionStorage; } catch (e) { }

// Kludge: This isn't a clean way to do it. But it works for now.
// It doesn't take into account collapsed state change that happen when expandTo
// is called. User must click the un-collapse arrow for that.
// This also relies on this file being loaded after full_list.js so that the
// original YARD enableToggles function is called before this one.
function persistentToggles() {
  // Remember the collapsed state when toggling the first two levels.
  $('#full_list a.toggle').on('click', function(evt) {
    console.log('persistentToggles');
    var $item = $(this).parent().parent();
    var key = $item.attr('id');
    var value = $item.hasClass('collapsed');
    localStorage.setItem(key, value);
  });
  // Load initial state.
  $('#full_list a.toggle').each(function() {
    var $item = $(this).parent().parent();
    var key = $item.attr('id');
    var value = localStorage.getItem(key);
    if (value === 'true') {
      $item.addClass('collapsed');
    }
  });
}

// YARD only listens for "input" and "change" on the search box, so pressing
// Enter does nothing. Open the first match instead. YARD searches in chunks, so
// while the "insearch" class is still on #full_list the match list may be
// incomplete; wait briefly for it to finish before choosing the first row.
function openFirstResultOnEnter() {
  var input = document.querySelector('#search input');
  if (!input) return;

  function openFirstMatch(attemptsLeft) {
    var list = document.getElementById('full_list');
    var searching = list && list.classList.contains('insearch') &&
      document.getElementById('content').classList.contains('insearch');
    if (searching) {
      // Still searching when the retry budget runs out: the found rows may
      // belong to a previous query, so don't navigate.
      if (attemptsLeft <= 0) return;
      var query = input.value;
      setTimeout(function() {
        // Abandon the retry if the query changed since Enter was pressed.
        if (input.value === query) openFirstMatch(attemptsLeft - 1);
      }, 50);
      return;
    }
    // YARD marks the .item row (not the <li>) with the "found" class.
    var link = document.querySelector('#full_list .item.found .object_link a');
    if (link) link.click();
  }

  input.addEventListener('keydown', function(evt) {
    if (evt.key !== 'Enter' || evt.isComposing || input.value === '') return;
    evt.preventDefault();
    openFirstMatch(40);
  });
}

$(document).ready(function() {
  console.log('READY: sketchup.js');
  persistentToggles();
  openFirstResultOnEnter();
});

})();
