/**
 * Javascript for page show.html.ep
 **/
$(document).ready(function () {
  $('.scales .btn').click(function (e) {
    var fromDate = new Date();
    var toDate = new Date();

    //switch($(this).attr('value')) {
    switch($(this).attr('id')) {
      case 'sel_year':
          fromDate.setYear(fromDate.getYear() + 1900 - 1);
        break;
        case 'sel_month':
          fromDate.setMonth(fromDate.getMonth() - 1);
        break;
        case 'sel_week':
          fromDate.setDate(fromDate.getDate() - 7);
        break;
        case 'sel_day':
          fromDate.setDate(fromDate.getDate() - 1);
        break;
        case 'sel_custom':
          if ($('#fromdate').attr('value') === '' ) {
            alert('you must set the starting date.');
            return false;
          }

          if ($('#todate').attr('value') === '' )
            /* set the toDate to the current day */
            $('#todate').attr('value', $.datepicker.formatDate('dd/mm/yy', toDate ));
          else
            toDate = $.datepicker.parseDate('dd/mm/yy', $('#todate').attr('value'));

          fromDate = $.datepicker.parseDate('dd/mm/yy', $('#fromdate').attr('value'));
        break;
    }
    $('#fromdate').attr('value',$.datepicker.formatDate('dd/mm/yy',fromDate));
    $('#todate').attr('value',$.datepicker.formatDate('dd/mm/yy',toDate));
    $('[id-graph]').grapher({from: fromDate.getTime(), to: toDate.getTime(), url: "/grapher/graphs/data" });
  })
  /* by default, show the week graph by triggering the week button */
  $('#sel_week').click();


  /* bind the datepicker to the date fields */
  $('.datepick').datepicker({
    autoFocusNextInput: true,
    showOn: 'focus',
    dateFormat: 'dd/mm/yy'
  });
});
