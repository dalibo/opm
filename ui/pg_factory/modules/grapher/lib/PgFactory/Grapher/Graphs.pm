package PgFactory::Grapher::Graphs;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub list {
    my $self = shift;

    my $dbh = $self->database;

    my $sth = $dbh->prepare(qq{SELECT g.id, g.graph, g.description, s2.hostname FROM pr_grapher.graphs g LEFT JOIN pr_grapher.graph_services gs ON gs.id_graph = g.id LEFT JOIN public.list_services() s1 ON s1.id = gs.id_service LEFT JOIN public.list_servers() s2 ON s2.id = s1.id_server ORDER BY hostname, graph});
    $sth->execute;
    my $graphs = [ ];
    while (my $row = $sth->fetchrow_hashref) {
        push @{$graphs}, $row;
    }
    $sth->finish;
    $dbh->commit;
    $dbh->disconnect;

    $self->stash(graphs => $graphs);

    $self->render;
}

sub show {
    my $self = shift;

    my $id = $self->param('id');

    my $dbh = $self->database;

    # Get the graph
    my $sth = $dbh->prepare(qq{SELECT graph, description FROM pr_grapher.graphs WHERE id = ?});
    $sth->execute($id);
    my $graph = $sth->fetchrow_hashref;
    $sth->finish;

    $dbh->commit;
    $dbh->disconnect;

    # Check if it exists (this can be reach by url)
    if (!defined $graph) {
        return $self->render_not_found;
    }

    $self->stash(graph => $graph);

    $self->render;

}

sub add {
    my $self = shift;

    my $e = 0;
    my $properties = $self->properties->load;

    my $method = $self->req->method;
    if ($method =~ m/^POST$/i) {
    # process the input data
        my $form = $self->req->params->to_hash;

    # Action depends on the name of the button pressed
        if (exists $form->{cancel}) {
            return $self->redirect_to('graphs_list');
        }

        if (exists $form->{save}) {
            if ($form->{graph} =~ m!^\s*$!) {
                $self->msg->error("Missing graph name");
                $e = 1;
            }
            if ($form->{y1_query} =~ m!^\s*$! && $form->{y2_query} =~ m!^\s*$!) {
                $self->msg->error("Missing query");
                $e = 1;
            }

            if (!$e) {
                # Prepare the configuration: save and clean the $form
                # hashref to keep only the properties, so that we can
                # use the plugin
                delete $form->{save};
                my $graph = $form->{graph};
                delete $form->{graph};
                my $description = ($form->{description} =~ m!^\s*$!) ? undef : $form->{description};
                delete $form->{description};
                my $y1_query = ($form->{y1_query} =~ m!^\s*$!) ? undef : $form->{y1_query};
                delete $form->{y1_query};
                my $y2_query = ($form->{y2_query} =~ m!^\s*$!) ? undef : $form->{y2_query};
                delete $form->{y2_query};

                my $props = $self->properties->validate($form);
                if (!defined $props) {
                    $self->msg->error("Bad input, please double check the options");
                    return $self->render;
                }

                # Only save the properties with different values from
                # the defaults
                my $config = Mojo::JSON->encode($self->properties->diff($properties, $props));

                my $dbh = $self->database;
                my $sth = $dbh->prepare(qq{INSERT INTO pr_grapher.graphs (graph, description, y1_query, y2_query, config) VALUES (?, ?, ?, ?, ?)});
                if (! defined $sth->execute($graph, $description, $y1_query, $y2_query, $config)) {
                    $self->render_exception($dbh->errstr);
                    $sth->finish;
                    $dbh->rollback;
                    $dbh->disconnect;
                    return;
                }
                $sth->finish;
                $self->msg->info("Graph saved");
                $dbh->commit;
                $dbh->disconnect;
                return $self->redirect_to('graphs_list');
            }
        }
    }

    if (!$e) {
        foreach my $p (keys %$properties) {
            $self->param($p, $properties->{$p});
        }
    }

    $self->render;
}

sub edit {
    my $self = shift;

    my $id = $self->param('id');
    my $e = 0;
    my $properties = $self->properties->load;


    my $dbh = $self->database;

    # Get the graph
    my $sth = $dbh->prepare(qq{SELECT graph, description, y1_query, y2_query, config
            FROM pr_grapher.graphs
            WHERE id = ?});
    $sth->execute($id);
    my $graph = $sth->fetchrow_hashref;
    $sth->finish;
    $dbh->commit;
    $dbh->disconnect;

    # Check if it exists
    if (! defined $graph) {
        return $self->render_not_found;
    }

    # Save the form
    my $method = $self->req->method;
    if ($method =~ m/^POST$/i) {
        # process the input data
        my $form = $self->req->params->to_hash;

    # Action depends on the name of the button pressed
        if (exists $form->{cancel}) {
            return $self->redirect_to('graphs_list');
        }

        if (exists $form->{save}) {
            if ($form->{graph} =~ m!^\s*$!) {
                $self->msg->error("Missing graph name");
                $e = 1;
            }
            if ($form->{y1_query} =~ m!^\s*$! && $form->{y2_query} =~ m!^\s*$!) {
                $self->msg->error("Missing query");
                $e = 1;
            }

            if (!$e) {
            # Prepare the configuration: save and clean the $form
            # hashref to keep only the properties, so that we can
            # use the plugin
                delete $form->{save};
                my $graph = $form->{graph};
                delete $form->{graph};
                my $description = ($form->{description} =~ m!^\s*$!) ? undef : $form->{description};
                delete $form->{description};
                my $y1_query = ($form->{y1_query} =~ m!^\s*$!) ? undef : $form->{y1_query};
                delete $form->{y1_query};
                my $y2_query = ($form->{y2_query} =~ m!^\s*$!) ? undef : $form->{y2_query};
                delete $form->{y2_query};

                my $props = $self->properties->validate($form);
                if (!defined $props) {
                    $self->msg->error("Bad input, please double check the options");
                    return $self->render;
                }

            # Only save the properties with different values from
            # the defaults
                my $config = Mojo::JSON->encode($self->properties->diff($properties, $props));

                my $dbh = $self->database;
                my $sth = $dbh->prepare(qq{UPDATE pr_grapher.graphs
                        SET graph = ?, description = ?, y1_query = ?, y2_query = ? , config = ?
                        WHERE id = ?});
                if (! defined $sth->execute($graph, $description, $y1_query, $y2_query, $config, $id)) {
                    $self->render_exception($dbh->errstr);
                    $sth->finish;
                    $dbh->rollback;
                    $dbh->disconnect;
                    return;
                }
                $sth->finish;
                $self->msg->info("Graph saved");
                $dbh->commit;
                $dbh->disconnect;
                return $self->redirect_to('graphs_list');
            }
        }
    }

    if (!$e) {
        # Prepare properties
        my $config = Mojo::JSON->decode($graph->{config});
        delete $graph->{config};

        @$properties{ keys %$config } = values %$config;

        foreach my $p (keys %$properties) {
            $self->param($p, $properties->{$p});
        }

        # Prefill the rest
        foreach my $p (keys %$graph) {
            $self->param($p, $graph->{$p});
        }
    }

    $self->render;
}

sub remove { }

sub data {
    my $self = shift;

    my $y1_query = $self->param('y1_query');
    my $y2_query = $self->param('y2_query');
    my $id = $self->param('id');
    my $properties = {};
    my $config;
    my $isservice = 0;
    my $data = [ ];

    # Double check the input
    if (!defined $y1_query && !defined $y2_query && !defined $id) {
        return $self->render_json({ error => "post: Bad input" });
    }

    my $dbh = $self->database;
    my $sth;
    # When a graph id is received, retrieve the queries and the properties from the DB
    if (defined $id) {
        $sth = $dbh->prepare(qq{SELECT y1_query, y2_query, config FROM pr_grapher.graphs WHERE id = ?});
        $sth->execute($id);

        ($y1_query, $y2_query, $config) = $sth->fetchrow;
        $sth->finish;

        $properties = $self->properties->load;
        if (defined $config) {
            $config = Mojo::JSON->decode($config);
            @$properties{ keys %$config } = values %$config;
        }
        #Is the graph linked to a service ?
        $sth=$dbh->prepare("SELECT COUNT(*) FROM pr_grapher.graph_services WHERE id_graph = ?");
        $sth->execute($id);
        my $result = $sth->fetchrow;
        $isservice = 1 if ($result == 1);
        $sth->finish;
    }

    if (not $isservice){
        if (defined $y1_query and $y1_query !~ m!^\s*$!) {
            my $series = { };

            $sth = $dbh->prepare($y1_query);
            if (! defined $sth->execute) {
                my $error = { error => '<pre>'.$dbh->errstr.'</pre>' };
                $sth->finish;
                $dbh->rollback;
                $dbh->disconnect;
                return $self->render_json($error);
            }

            # Use the NAME attribute of the statement handle to have the order
            # of the columns. Since we are working with hashes to build the
            # series form the columns names, this let us output the right
            # order which is not garantied by walking keys of a hash.
            my @cols = @{$sth->{NAME}};

            # The first columns is always the x value of the point.
            my $first_col = shift @cols;

            # Build the data struct for Flotr: a hash of series labels with
            # lists of points. Points are list of x,y values)
            while (my $row = $sth->fetchrow_hashref) {
                my $x = $row->{$first_col};
                foreach my $c (@cols) {
                    $series->{$c} = [ ] if ! exists $series->{$c};
                    push @{$series->{$c}}, [ $x, $row->{$c} ];
                }
            }
            $sth->finish;

            # Create the final struct: a list of hashes { data: [], label: "col" }
            foreach my $c (@cols) {
                push @{$data}, { data => $series->{$c}, label => $c }
            }
        }

        if (defined $y2_query and $y2_query !~ m!^\s*$!) {
            # Do the same for y2
            my $series = { };
            $sth = $dbh->prepare($y2_query);

            if (! defined $sth->execute) {
                my $error = { error => '<pre>'.$dbh->errstr.'</pre>' };
                $sth->finish;
                $dbh->rollback;
                $dbh->disconnect;
                return $self->render_json($error);
            }

            my @cols = @{$sth->{NAME}};
            my $first_col = shift @cols;
            while (my $row = $sth->fetchrow_hashref) {
                my $x = $row->{$first_col};
                foreach my $c (@cols) {
                    $series->{$c} = [ ] if ! exists $series->{$c};
                    push @{$series->{$c}}, [ $x, $row->{$c} ];
                }
            }
            $sth->finish;

            # Create the final struct: a list of hashes { data: [], label: "col", yaxis : 2 }
            foreach my $c (@cols) {
                push @{$data}, { data => $series->{$c}, label => $c }
            }
        }
    } else{
        $sth = $dbh->prepare(qq{SELECT id_label, label, oldest_record FROM pr_grapher.graph_services gs JOIN wh_nagios.services_labels sl ON gs.id_service = sl.id WHERE gs.id_graph = ?});
        $sth->execute($id);

        my $series = { };
        my $sql;
        while ( my ($id_label, $label, $oldest_record) = $sth->fetchrow()){
            $sql = $dbh->prepare("SELECT pr_grapher.js_time(timet), value as $label FROM wh_nagios.get_sampled_label_data(?, ?, now(), 300);");
            $sql->execute($id_label,$oldest_record);
            $series->{$label} = [ ];
            while (my ($x,$y) = $sql->fetchrow()){
                push @{$series->{$label}}, [ $x, $y ];
            }
            $sql->finish;
            push @{$data}, { data => $series->{$label}, label => $label }
        }
        $sth->finish;
        $dbh->commit;
        $dbh->disconnect;

        if (!scalar(@$data)) {
            return $self->render_json({ error => "Empty output" });
        }
    }

    return $self->render_json({ series => $data, properties => $self->properties->to_plot($properties) });

}

sub series_add { }

sub series_edit { }

sub series_remove { }

1;
