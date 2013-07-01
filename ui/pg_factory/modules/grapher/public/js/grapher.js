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
            $legend.empty();

            // Fetch to data to plot
            this.fetch_data(url);

            if (this.fetched.error != null) {
                $plot.append(grapher.html_error(this.fetched.error));
                return;
            }

            this.show();

            this.drawLegend();
        },

        show: function () {
            var $this      = this.element,
                properties = this.fetched.properties,
                series     = this.fetched.series,
                graph      = null
                container  = $this.find('.plot').get(0);

            $this.find('.plot').empty();
            $this.find('.plot').unbind();

            // Draw the graph
            graph = Flotr.draw(container, series, properties);

            this.flotr = graph;
        },

        drawLegend: function() {

            var $this      = this.element,
                $legend    = $this.find('.legend'),
                legend_opt = this.flotr.legend.options,
                series     = this.flotr.series,
                fragments  = [],
                i, label, color,
                itemCount  = $.grep(series, function (e) {
                    return (e.label && !e.hide) }
                ).length;

            if (itemCount) {

                for(i = 0; i < series.length; ++i){
                    if(!series[i].label) continue;

                    var s = series[i],
                        boxWidth = legend_opt.labelBoxWidth,
                        boxHeight = legend_opt.labelBoxHeight;

                    label = legend_opt.labelFormatter(s.label);
                    color = 'background-color:' + ((s.bars && s.bars.show && s.bars.fillColor && s.bars.fill) ? s.bars.fillColor : s.color) + ';';

                    var $cells = $(
                        '<td class="flotr-legend-color-box">'+
                            '<div id="legendcolor'+i+'" style="border:1px solid '+ legend_opt.labelBoxBorderColor+ ';padding:1px">'+
                                '<div style="width:'+ (boxWidth-1) +'px;height:'+ (boxHeight-1) +'px;border:1px solid '+ series[i].color +'">'+ // Border
                                    '<a style="display:block;width:'+ boxWidth +'px;height:'+ boxHeight +'px;'+ color +'"></a>'+ // Background
                                '</div>'+
                            '</div>'+
                        '</td>'+
                        '<td class="flotr-legend-label">'+
                            '<label>'+ label +'</label>'+
                        '</td>'
                    );

                    $cells.find('a, label')
                        .data('i', i)
                        .data('grapher', this)
                        .click(function () {
                            var grapher = $(this).data('grapher'),
                                i       = $(this).data('i'),
                                flotr   = grapher.flotr,
                                s       = grapher.fetched.series[i],
                                color;

                            s.hide = ! s.hide;
                            if (s.hide)
                                $('#legendcolor'+i).hide();
                            else
                                $('#legendcolor'+i).show();
                            grapher.show();
                        });

                    fragments.push($cells);
                }

                if(fragments.length > 0){
                    var $table = $('<table style="font-size:smaller;color:'+ this.flotr.options.grid.color +'" />');
                    var $tr = $('<tr />');

                    for(i = 0; i < fragments.length; i++) {
                        if((i !== 0) && (i % legend_opt.noColumns === 0)) {
                            $table.append($tr);
                            $tr = $('<tr />');
                        }
                        $tr.append(fragments[i]);
                    }
                    $table.append($tr);
                    $legend.append($table);
                }
            }
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
