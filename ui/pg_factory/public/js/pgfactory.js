function displayResult(item, val, text) {
      console.log(item);
          //alert('You selected <strong>' + val + '</strong>: <strong>' + text + '</strong>');
          window.location = '/server/' + val;
}

$(document).ready(function (){
    $('#search').typeahead({
      ajax: { url: '/search/server', triggerLength: 1},
      itemSelected: displayResult
    });
});
