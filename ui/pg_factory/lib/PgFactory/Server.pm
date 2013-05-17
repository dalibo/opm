package PgFactory::Server;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);


sub list{
    my $self = shift;
    my $dbh = $self->database();
    my $sql;

    $sql = $dbh->prepare("SELECT hostname FROM public.list_servers() ORDER BY 1;");
    $sql->execute();
    my $servers = [];
    while (my $v = $sql->fetchrow()){
        push @{$servers},{hostname => $v};
    }
    $sql->finish();

    $self->stash(servers => $servers);

    $dbh->disconnect();
    $self->render();
}

sub service{
    my $self = shift;
    my $dbh = $self->database();
    my $sql;

    $sql = $dbh->prepare("SELECT s1.id, s2.hostname FROM public.list_services() s1 JOIN public.list_servers s2 ON s2.id = s1.id_server ORDER BY 1;");
    $sql->execute();
    my $servers = [];
    while (my $v = $sql->fetchrow()){
        push @{$servers},{hostname => $v};
    }
    $sql->finish();

    $self->stash(servers => $servers);

    $dbh->disconnect();
    $self->render();
}

sub host{
    my $self = shift;
    my $dbh = $self->database();
    my $hostname = $self->param('hostname');
    my $sql;

    $sql = $dbh->prepare("SELECT pr_grapher.create_graph_for_services(id) FROM public.list_servers() WHERE hostname = ?");
    $sql->execute($hostname);
    $sql->finish();

    $sql = $dbh->prepare("SELECT s1.id,s1.warehouse,s1.service,s1.last_modified,s1.creation_ts,s1.servalid, g.id, g.graph FROM public.list_services() s1 JOIN public.list_servers() s2 ON s2.id = s1.id_server JOIN pr_grapher.graph_services gs ON gs.id_service = s1.id JOIN pr_grapher.graphs g ON g.id = gs.id_graph WHERE s2.hostname = ?;");
    $sql->execute($hostname);
    my $services = [];
    while (my ($id,$warehouse,$service,$last_mod,$creation_ts,$servalid,$id_graph,$graphname) = $sql->fetchrow()){
        push @{$services},{ id => $id, warehouse => $warehouse, servicename => $service, lst_mod => $last_mod, creation_ts => $creation_ts, servalid => $servalid, id_graph => $id_graph, graphname => $graphname};
    }
    $sql->finish();

    $self->stash(services => $services);

    $dbh->disconnect();
    $self->render();
}


1;
