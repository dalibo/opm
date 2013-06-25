(function($) {

  var Grapher = function (element, options) {
    var g = this;
    this.config = options;
    this.element = $(element);

    this.datasource = $(options.datasource);
    this.properties = $(options.properties);

    this.plot_defaults = {
      shadowSize: 0,
      legend: {
        position: 'ne'
      },
      autoscale: true,
      HtmlText: false,
      yaxis: {
	autoscale: true,
	autoscaleMargin: 5
      },
      xaxis: {
        mode: 'time',
	autoscale: true,
	autoscaleMargin: 5
	},
      selection : { mode : 'x', fps : 30 }
    };

    // When controls are given, setup the events
    if (options.datasource !== null && options.properties !== null) {
      this.properties.find('input[type=checkbox]').change(function () { g.draw() });
      this.properties.find('input[type=radio]').change(function () { g.draw() });
      this.properties.find('input[type=text]').change(function () { g.draw() });
      this.properties.find('select[name=xaxis_mode]').change(function () { g.draw() });
      // enter / return keys on text inputs ?
    }
  }

  Grapher.prototype = {

    constructor: Grapher,

    html_error: function (message) {
      if (typeof message == 'undefined') message = '';

      return '<div class="alert alert-error">'+
	'<button type="button" class="close" data-dismiss="alert">&times;</button>'+
	'<strong>Error:</strong> '+ message +
	'</div>';
    },

    get_property: function (name, checked) {
      if (checked)
	return this.properties.find('input[name="'+name+'"]:checked').val();
      else
	return this.properties.find('input[name="'+name+'"]').val();
    },

    options: function () {
      var $properties = this.properties,
      $datasource = this.datasource,
      $this = this.element;

      // get all properties values from the form
      var options = { };

      // Series
      // TODO: colors
      options['legend'] = {
	container: (this.get_property('show_legend', true) ? null : $this.find('.legend').get(0))
      };

      // X axis
      options['xaxis'] = {
	showLabels: (this.get_property('xaxis_showLabels', true) ? true : false),
	labelsAngle: parseFloat(this.get_property('xaxis_labelsAngle')),
	title: this.get_property('xaxis_title'),
	titleAngle: parseFloat(this.get_property('xaxis_titleAngle')),
	timeFormat: this.get_property('xaxis_timeFormat'),
	mode: this.properties.find('select[name=xaxis_mode]').val()
      };

      // Y axis
      options['yaxis'] = {
	showLabels: (this.get_property('yaxis_showLabels', true) ? true : false),
	labelsAngle: parseFloat(this.get_property('yaxis_labelsAngle')),
	title: this.get_property('yaxis_title'),
	titleAngle: parseFloat(this.get_property('yaxis_titleAngle'))
      };
      options['y2axis'] = {
	showLabels: (this.get_property('y2axis_showLabels', true) ? true : false),
	labelsAngle: parseFloat(this.get_property('y2axis_labelsAngle')),
	title: this.get_property('y2axis_title'),
	titleAngle: parseFloat(this.get_property('y2axis_titleAngle'))
      };

      // Series type properties
      var type = this.get_property('type', true);
      switch (type) {
      case 'bars':
	options['bars'] = {
	  show: true,
	  lineWidth: parseFloat(this.get_property('bars_lineWidth')),
	  barWidth: parseFloat(this.get_property('bars_barWidth')),
	  stacked: (this.get_property('bars_stacked', true) ? true : false),
	  fill: (this.get_property('bars_filled', true) ? true : false),
	  grouped: (this.get_property('bars_grouped', true) ? true : false)
	};
	break;
      case 'lines':
	options['lines'] = {
	  show: true,
	  lineWidth: parseFloat(this.get_property('lines_lineWidth')),
	  stacked: (this.get_property('lines_stacked', true) ? true : false),
	  fill: (this.get_property('lines_filled', true) ? true : false)
	};
	break;
      case 'points':
	options['points'] = {
	  show: true,
	  lineWidth: parseFloat(this.get_property('points_lineWidth')),
	  radius: parseFloat(this.get_property('points_radius')),
	  fill: (this.get_property('points_filled', true) ? true : false)
	};
	break;
      case 'pie':
	options['pie'] = {
	  show: true,
	  lineWidth: parseFloat(this.get_property('pie_lineWidth')),
	  fill: (this.get_property('pie_filled', true) ? true : false)
	};
	break;
      }
 
      return $.extend(true, {}, this.plot_defaults, options);
      
    },

    draw: function () {
      var $this = this.element,
      $datasource = this.datasource,
      $plot = $this.find('.plot'),
      $save = $this.find('.save'),
      $legend = $this.find('.legend')
      post_data = { }, grapher = this,
      url = (this.config['url'] == null ? '/graphs/data' : this.config['url'])
      fromDate = this.config['from'],
      toDate = this.config['to'];

      // Empty the graph to draw it from scratch
      $plot.empty();
      $plot.unbind();
      $save.unbind();
      $legend.empty();

      // when no graph id is given, find the queries in the page
      if (this.config.id == null) {
	var y1 = $datasource.find('textarea[name=y1_query]').val(),
	y2 = $datasource.find('textarea[name=y2_query]').val();

	if (!y1.length && !y2.length) {
	  $plot.append(grapher.html_error('Empty queries'));
	  return;
	}

	post_data = { y1_query: y1,
		      y2_query: y2,
          from: fromDate,
          to: toDate
		    };
      } else {
	post_data = { id: this.config.id,
          from: fromDate,
          to: toDate
   };
      }

      // Send the request for the data, everything is done inside the
      // success callback because .post() is executed asynchronously
      $.post(url, post_data,
	     function (result) {
	       var graph,
	       container = $plot.get(0),
	       options;

	       if (result.error != null) {
		 // display the error in the container, instead of the graph	
		 $plot.append(grapher.html_error(result.error));
	       } else {
		 // Process the options
		 options = $.extend(true, {}, grapher.options(), result.properties || {});

		 // Set the legend container, it cannot be done on the
		 // server side.
		 if (options.legend['container'] !== null)
		   options.legend['container'] = $legend.get(0);

		 // Draw the graph
		 graph = Flotr.draw(container, result.series, options);

		 // Bind the save action
		 $save.click(function (e) {
		   e.preventDefault();
		   graph.download.saveImage('png', null, null, false);
		 });

		 // Bind the selection

		 Flotr.EventAdapter.observe(container, 'flotr:select', function (sel, g) {
		   var zoom = {
		     xaxis: {
		       min: sel.x1,
		       max: sel.x2
		     },
		     yaxis: {
		       min: sel.y1,
		       max: sel.y2
		     }
		   },
		   zo = $.extend(true, {}, options, zoom);

		   // Save the zoom information
		   var zl = $this.data('grapher-zoom') || [];
		   zl.push(zoom);
		   $this.data('grapher-zoom', zl);

		   $legend.empty();
		   graph = Flotr.draw(container, result.series, zo);
		 });

		 // When graph is clicked, draw the graph with default area
		 Flotr.EventAdapter.observe(container, 'flotr:click', function () {
		   var zl = $this.data('grapher-zoom'),
		   zoom, zo;

		   // Remove the current zoom information and get the previous
		   zl.pop();
		   zoom = zl[zl.length-1];

		   zo = $.extend(true, {}, options, zoom || { });
		   
		   $legend.empty();
		   graph = Flotr.draw(container, result.series, zo);
		 });
	       }

	     },
	     'json');

    }
  }

  // Plugin definition
  $.fn.grapher = function (option) {
    return this.each(function () {
      var $this = $(this)
      , data = $this.data('grapher')
      , options = $.extend({}, $.fn.grapher.defaults, typeof option == 'object' && option)
      if ( (!data) || (typeof option != 'undefined') ) $this.data('grapher', (data = new Grapher(this, options)))
      if (typeof option == 'string') data[option]()
      else if (options.draw) data.draw()
    })
  }

  $.fn.grapher.defaults = {
    datasource: null,
    properties: null,
    id: null,
    draw: true,
    url: null,
    from: null,
    to: null
  }

})(jQuery);
