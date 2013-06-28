(function($) {

    var Grapher = function (element, options) {
        var g = this;
        this.config = options;
        this.element = $(element);

        this.default_props = {
            shadowSize: 0,
            legend: { position: 'ne' },
            autoscale: true,
            HtmlText: false,
            yaxis: {
                autoscale: true,
                autoscaleMargin: 5
            },
            xaxis: {
                mode: 'time',
                autoscale: false,
                autoscaleMargin: 5
            },
            selection : {
                mode : 'x',
                fps : 30
            }
        };

        this.element.append('<div class="plot span9">')
            .append('<div class="legend span3"></div>');
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

        fetch_data: function (url, fromDate, toDate) {

            var grapher = this, post_data;

            if (fromDate == null)
                fromDate = grapher.config.from;

            if (toDate == null)
                toDate = grapher.config.to;

            post_data = {
                    id: this.config.id,
                    from: fromDate,
                    to: toDate
                };

            var a = $.ajax(url, {
                async: false,
                cache: false,
                type: 'post',
                url: url,
                dataType: 'json',
                data: post_data,
                success: function (r) {
                    grapher.fetched = r;
                    if (r.error === null)
                        grapher.fetched.properties = $.extend(true,
                            grapher.default_props,
                            grapher.fetched.properties || {}
                        );
                }
            });
        },

        draw: function () {
            var $this       = this.element,
                $plot       = $this.find('.plot'),
                $legend     = $this.find('.legend'),
                graph       = null,
                container   = $plot.get(0),
                grapher     = this,
                url         = this.config['url'],
                properties,
                series;

            // Empty the graph to draw it from scratch
            $plot.empty();
            $plot.unbind();
            $legend.empty();

            // Fetch to data to plot
            this.fetch_data(url);

            if (this.fetched.error != null) {
                $plot.append(grapher.html_error(this.fetched.error));
                return;
            }

            properties = this.fetched.properties;
            series = this.fetched.series;

            // Draw the graph
            graph = Flotr.draw(container, series, properties);

            grapher.flotr = graph;
        }
    };

    // Plugin definition
    $.fn.grapher = function (option) {
        return this.each(function () {

            var $this = $(this),
                grapher = $this.data('grapher');

            if (!grapher) {
                var options = $.extend({}, {
                        properties: null,
                        id:         null,
                        to:         null,
                        from:       null,
                        draw:       true,
                        url:        null
                    },
                    typeof option == 'object' && option
                );

                options.id = $this.attr('id-graph');

                if (options.id === undefined) return;

                $this.data('grapher', (grapher = new Grapher(this, options)));

                Flotr.EventAdapter.observe($this.find('.plot').get(0), 'flotr:select', function (sel, g) {

                    grapher.config = $.extend(grapher.config, {
                        from: Math.round(sel.x1),
                        to: Math.round(sel.x2)
                    });

                    grapher.draw();

                });

                Flotr.EventAdapter.observe($this.find('.plot').get(0), 'flotr:click', function () {

                    var zo = $this.data('orig_win');

                    grapher.config = $.extend(grapher.config, {
                        from: zo[0],
                        to: zo[1]
                    });

                    grapher.draw();
                });
            }

            if (typeof option == 'object') {
                grapher.config = $.extend(grapher.config, option);
            }

            $this.data('orig_win', [option.from, option.to]);

            if (grapher.config.draw) grapher.draw();

        })
    }

})(jQuery);
