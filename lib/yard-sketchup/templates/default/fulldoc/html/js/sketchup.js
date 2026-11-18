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

// YARD 0.9.41+ counts every visible <li> when reporting search results. While
// searching, non-matching rows only have their .item hidden, so the <li> itself
// still counts and the reported total is wrong. Rewrite the message using the
// number of rows actually marked as found.
// #noresults is created by full_list.js after jQuery's ready callbacks have
// run, so this must be attached once the window has loaded.
function fixSearchResultCount() {
  var noResults = document.getElementById('noresults');
  if (!noResults) return;
  var observer = new MutationObserver(function() {
    if (!/^There are \d+ results\.$/.test(noResults.textContent)) return;
    var found = document.querySelectorAll('#full_list .found').length;
    var message = found === 0 ?
      'No results were found.' : 'There are ' + found + ' results.';
    // Writing the message triggers this observer again, so only write when it
    // differs.
    if (noResults.textContent !== message) noResults.textContent = message;
  });
  observer.observe(noResults, { childList: true, characterData: true, subtree: true });
}

// YARD re-runs the search on the search box's "change" event, which fires when
// the box loses focus. Clicking a result blurs the box, and the re-run rewrites
// the matched text inside the result's link, removing the element under the
// mouse before the click completes, so the first click on a result is lost.
// The "input" event already keeps results up to date while typing, so stop
// "change" before it reaches YARD's handler.
function ignoreSearchChangeEvents() {
  document.addEventListener('change', function(evt) {
    var target = evt.target;
    if (target && target.closest && target.closest('#search')) {
      evt.stopImmediatePropagation();
    }
  }, true);
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
    if (searching && attemptsLeft > 0) {
      setTimeout(function() { openFirstMatch(attemptsLeft - 1); }, 50);
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
  ignoreSearchChangeEvents();
  persistentToggles();
  openFirstResultOnEnter();
});

$(window).on('load', fixSearchResultCount);

})();
