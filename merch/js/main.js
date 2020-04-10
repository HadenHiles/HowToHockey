$(document).ready(function () {
  history.replaceState && history.replaceState(
    null, '', location.pathname + location.search.replace(/[\?&]subscribed=[^&]+/, '').replace(/^&/, '?').replace(/[\#&]newsletter=[^&]+/, '').replace(/^&/, '#')
  );
});
