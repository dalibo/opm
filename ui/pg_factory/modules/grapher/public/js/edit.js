/**
 * Javascript for page edit.html.ep
**/

function toggleGraphType(){
  $('.graph_type').hide();
  $('#type_'+$('#graph_type_select').find('option:selected').val()).show();
};

$(document).ready(function () {
  // Handle graph type selector
  $('#graph_type_select').change(function (e) {
    if ( $('#graph_type_select option:selected').val() != '')
      toggleGraphType();
  });
  // Need to call it the first time
  toggleGraphType();
});
