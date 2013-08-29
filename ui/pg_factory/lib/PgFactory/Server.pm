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
        "SELECT id, hostname, COALESCE(rolname,'') FROM public.list_servers() ORDER BY rolname;");
    $sql->execute();
    my $servers = [];
    while ( my ( $id, $hostname, $rolname ) = $sql->fetchrow() ) {
        push @{$servers}, { id => $id, hostname => $hostname, rolname => $rolname };
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

    $sql = $dbh->prepare("SELECT COUNT(*) FROM public.list_servers() WHERE id = ?");
    $sql->execute($id);
    my $found = ( $sql->fetchrow() == 1 );
    $sql->finish();

    if (! $found){
        $dbh->disconnect();
        return $self->render_not_found;
    }

    # FIXME: handle pr_grapher dependancy
    $sql = $dbh->prepare("SELECT pr_grapher.create_graph_for_wh_nagios(?)");
    $sql->execute($id);
    $sql->finish();
    $dbh->commit();

    $dbh = $self->database();

    # FIXME: handle pr_grapher and wh_nagios dependancy
    $sql = $dbh->prepare(
        "SELECT DISTINCT s.id,s.warehouse,s.service,s.last_modified,
            s.creation_ts,lower(s.state) as state
        FROM wh_nagios.services s
        WHERE EXISTS (
                SELECT 1
                FROM wh_nagios.labels AS l
                JOIN pr_grapher.graph_wh_nagios AS gs ON gs.id_label=l.id
                WHERE s.id = l.id_service
            )
            AND s.id_server = ?;
        "
    );
    $sql->execute($id);
    my $services = [];
    while (
        my ( $id, $warehouse, $service, $last_mod, $creation_ts, $state )
            = $sql->fetchrow()
    ) {
        push @{$services}, {
            id          => $id,
            warehouse   => $warehouse,
            servicename => $service,
            lst_mod     => $last_mod,
            creation_ts => $creation_ts,
            state       => $state
        };
    }
    $sql->finish();

    $sql = $dbh->prepare(
        "SELECT hostname FROM public.list_servers() WHERE id = ?");
    $sql->execute($id);
    my $hostname = $sql->fetchrow();
    $sql->finish();

    $self->stash( services => $services, hostname => $hostname, id => $id );

    $dbh->disconnect();
    $self->render();
}

1;
