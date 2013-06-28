package PgFactory::Server;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);

sub list {
    my $self = shift;
    my $dbh  = $self->database();
    my $sql;

    $sql = $dbh->prepare(
        "SELECT id, hostname FROM public.list_servers() ORDER BY 1;");
    $sql->execute();
    my $servers = [];
    while ( my ( $id, $hostname ) = $sql->fetchrow() ) {
        push @{$servers}, { id => $id, hostname => $hostname };
    }
    $sql->finish();

    $self->stash( servers => $servers );

    $dbh->disconnect();
    $self->render();
}

sub service {
    my $self = shift;
    my $dbh  = $self->database();
    my $sql;

    $sql = $dbh->prepare(
        "SELECT s1.id, s2.hostname FROM public.list_services() s1 JOIN public.list_servers s2 ON s2.id = s1.id_server ORDER BY 1;"
    );
    $sql->execute();
    my $servers = [];
    while ( my $v = $sql->fetchrow() ) {
        push @{$servers}, { hostname => $v };
    }
    $sql->finish();

    $self->stash( servers => $servers );

    $dbh->disconnect();
    $self->render();
}

sub host {
    my $self = shift;
    my $dbh  = $self->database();
    my $id   = $self->param('id');
    my $sql;

    $sql = $dbh->prepare("SELECT pr_grapher.create_graph_for_services(?)");
    $sql->execute($id);
    $sql->finish();
    $dbh->commit();

    $dbh = $self->database();

    $sql = $dbh->prepare(
        "SELECT s.id,s.warehouse,s.service,s.last_modified,s.creation_ts,s.servalid, g.id, g.graph FROM public.list_services() s JOIN pr_grapher.list_graph() g ON g.id_service = s.id WHERE s.id_server = ?;"
    );
    $sql->execute($id);
    my $services = [];
    while (
        my ($id,          $warehouse, $service,  $last_mod,
            $creation_ts, $servalid,  $id_graph, $graphname )
        = $sql->fetchrow() )
    {
        push @{$services},
            {
            id          => $id,
            warehouse   => $warehouse,
            servicename => $service,
            lst_mod     => $last_mod,
            creation_ts => $creation_ts,
            servalid    => $servalid,
            id_graph    => $id_graph,
            graphname   => $graphname };
    }
    $sql->finish();

    $sql = $dbh->prepare(
        "SELECT hostname FROM public.list_servers() WHERE id = ?");
    $sql->execute($id);
    my $hostname = $sql->fetchrow();
    $sql->finish();

    $self->stash( services => $services, hostname => $hostname );

    $dbh->disconnect();
    $self->render();
}

1;
