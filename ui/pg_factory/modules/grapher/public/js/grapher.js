(function($) {

    var Grapher = function (element, options) {
        this.config = options;
        this.$element = $(element);

        this.default_props = {
            shadowSize: 0,
            legend: { position: 'ne' },
            autoscale: true,
            HtmlText: false,
            yaxis: {
                autoscale: true,
                autoscaleMargin: 5,
                tickFormatter: function (val, axis) {
                    var unit = this.unit;

                    if (unit == null) unit = '';
                    switch ( unit ) {
                        case 'B':
                            if (val > (1024*1024*1024*1024*1024))
                                return (val / (1024*1024*1024*1024*1024)).toFixed(2) + " Pi" + unit;
                            if (val > (1024*1024*1024*1024))
                                return (val / (1024*1024*1024*1024)).toFixed(2) + " Ti" + unit;
                            if (val > (1024*1024*1024))
                                return (val / (1024*1024*1024)).toFixed(2) + " Gi" + unit;
                            if (val > (1024*1024))
                                return (val / (1024*1024)).toFixed(2) + " Mi" + unit;
                            if (val > 1024)
                                return (val / 1024).toFixed(2) + " ki" + unit;
                            return val + " " + unit;
                        break;

                        case 's':
                            var minute = 60;
                            var hour = 60 * minute;
                            var day = 24 * hour;
                            var year = 365 * day;
                            function formatyear(t){
                                if (t < year)
                                    return formatday(t);
                                else
                                    return Math.floor(t/year)+'y '+formatday(t%year);
                            }
                            function formatday(t){
                                if (t < day)
                                    return formathour(t);
                                else
                                    return Math.floor(t/day)+'d '+formathour(t%day);
                            }
                            function formathour(t){
                                if (t < hour)
                                    return formatminute(t);
                                else
                                    return Math.floor(t/hour)+'h '+formatminute(t%hour);
                            }
                            function formatminute(t){
                                if (t < minute)
                                    return t+'s';
                                else
                                    return Math.floor(t/minute)+'m '+(t%minute)+'s';
                            }
                            return formatyear(val);
                        break;

                        default:
                            return val + " " + unit;
                        break;
                    }
                }
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

        this.$element.append('<div class="plot span9">')
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

            var grapher = this,
                post_data;

            if (fromDate == null)
                fromDate = this.config.from;

            if (toDate == null)
                toDate = this.config.to;

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
                    if (! r.error)
                        grapher.fetched.properties = $.extend(true,
                            grapher.default_props,
                            grapher.fetched.properties || {}
                        );
                }
            });
        },

        draw: function () {
            var $plot       = this.$element.find('.plot'),
                $legend     = this.$element.find('.legend');

            // Empty the graph to draw it from scratch
            $legend.empty();

            // Fetch to data to plot
            this.fetch_data(this.config['url']);
            //console.log(this.fetched.properties.yaxis);

            if (this.fetched.error != null) {
                $plot.append(this.html_error(this.fetched.error));
                return;
            }

            this.refresh();

            this.drawLegend();
        },

        refresh: function () {
            var properties = this.fetched.properties,
                series     = this.fetched.series,
                container  = this.$element.find('.plot').get(0);

            this.$element.find('.plot').unbind().empty();

            // Draw the graph
            this.flotr = Flotr.draw(container, series, properties);
        },

        drawLegend: function() {

            var $legend    = this.$element.find('.legend'),
                legend_opt = this.flotr.legend.options,
                series     = this.flotr.series,
                fragments  = [],
                i, label, color,
                itemCount  = $.grep(series, function (e) {
                        return (e.label && !e.hide) }
                    ).length;

            if (itemCount) {
                for(i = 0; i < series.length; ++i) {
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
                        .click(function () {
                            var grapher = $(this).parents('[id-graph]').data('grapher'),
                                i       = $(this).data('i'),
                                s       = grapher.fetched.series[i];

                            s.hide = ! s.hide;
                            if (s.hide)
                                $('[id-graph='+grapher.config.id+']').find('#legendcolor'+i).hide();
                            else
                                $('[id-graph='+grapher.config.id+']').find('#legendcolor'+i).show();

                            grapher.refresh();
                        });

                    fragments.push($cells);
                }

                if(fragments.length > 0) {
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
        },

        export: function() {
            var legend_shown = this.fetched.properties.legend.show;
            if (!legend_shown) {
                this.fetched.properties.legend.show = true;
                this.refresh();
            }
            this.flotr.download.saveImage('png', null, null, false);
            if (!legend_shown) {
                this.fetched.properties.legend.show = legend_shown;
                this.refresh();
            }
        },

        activateSeries: function () {
            var series     = this.fetched.series,
                i;

            for(i = 0; i < series.length; ++i)
                series[i].hide = false;

            this.$element.find('.legend .flotr-legend-color-box > div').show();

            this.refresh();
        },

        deactivateSeries: function () {
            var series     = this.fetched.series,
                i;

            for(i = 0; i < series.length; ++i)
                series[i].hide = true;

            this.$element.find('.legend .flotr-legend-color-box > div').hide();

            this.refresh();
        },

        invertActivatedSeries: function () {
            var series      = this.fetched.series,
                legendItems = this.$element
                    .find('.legend .flotr-legend-color-box > div'),
                i;

            for(i = 0; i < series.length; ++i) {
                series[i].hide = ! series[i].hide;

                if (series[i].hide)
                    $(legendItems[i]).hide();
                else
                    $(legendItems[i]).show();
            }

            this.refresh();
        }
    };

    // Plugin definition
    $.fn.grapher = function (option) {
        return this.each(function () {

            var $this = $(this),
                grapher = $this.data('grapher');

            // if no grapher object is already registred on this tag, add it
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
                $this.data('orig_win', [option.from, option.to]);
            }

            if (grapher.config.draw) grapher.draw();

        })
    }

})(jQuery);
