/**
 * Javascript for page edit.html.ep
**/

function toggleGraphType(){
  $('.graph_type').hide();
  $('#type_'+$('#graph_type_radio').find('input:checked').val()).show();
};
$(document).ready(function () {
  $('#graph_type_radio').find('.radio').click(toggleGraphType);
  toggleGraphType();
});
