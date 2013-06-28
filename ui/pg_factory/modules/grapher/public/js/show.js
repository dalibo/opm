/**
 * Javascript for page show.html.ep
 **/
$(document).ready(function () {
  /* bind the datetimepicker to the date fields */
  $('.datepick').datetimepicker({
    format: 'dd/MM/yyyy hh:mm:ss'
  });

  $('.scales .btn').click(function (e) {
    var fromDate = new Date();
    var toDate = new Date();
    var frompick = $('#fromdatepick').data('datetimepicker');
    var topick = $('#todatepick').data('datetimepicker');

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
          if (frompick.getDate() === null ) {
            alert('you must set the starting date.');
            return false;
          }
          if (topick.getDate() === null)
            /* set the toDate to the current day */
            topick.setDate(toDate.getDate());
          else
            toDate = topick.getDate();

          fromDate = frompick.getDate();
        break;
    }
    frompick.setDate(fromDate);
    topick.setDate(toDate);
    $('[id-graph]').grapher({from: fromDate.getTime(), to: toDate.getTime(), url: "/grapher/graphs/data" });
  });

    $('[export-graph]').click(function (e) {
        e.preventDefault();
        var id = $(this).attr('export-graph'),
            grapher = $('[id-graph='+id+']').data('grapher');

        grapher.flotr.download.saveImage('png', null, null, false);
    });

  /* by default, show the week graph by triggering the week button */
  $('#sel_week').click();
});
