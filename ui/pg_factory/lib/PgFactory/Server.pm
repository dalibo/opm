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

    $sql = $dbh->prepare("SELECT DISTINCT hostname FROM public.list_services() ORDER BY 1;");
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

    $sql = $dbh->prepare("SELECT id,hostname FROM public.list_services() ORDER BY 1;");
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


1;
