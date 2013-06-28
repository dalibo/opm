package PgFactory::User;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);

sub list {
    my $self = shift;
    my $dbh  = $self->database();
    my $sql;

    my $method = $self->req->method;
    if ( $method =~ m/^POST$/i ) {    # Create a new user
                                      # process the input data
        my $form_data = $self->req->params->to_hash;

        # Check input values
        my $e = 0;
        if ( $form_data->{username} =~ m/^\s*$/ ) {
            $self->msg->error("Empty username.");
            $e = 1;
        }
        if ( $form_data->{accname} =~ m/^\s*$/ ) {
            $self->msg->error("Empty account name.");
            $e = 1;
        }
        if ( $form_data->{password} =~ m/^\s*$/ ) {
            $self->msg->error("Empty password.");
            $e = 1;
        }

        if ( !$e ) {
            $sql =
                $dbh->prepare( "SELECT public.create_user('"
                    . $form_data->{username} . "','"
                    . $form_data->{password} . "','{"
                    . $form_data->{accname}
                    . "}');" );
            if ( $sql->execute() ) {
                $self->msg->info("User added");
                $dbh->commit() if (!$dbh->{AutoCommit});
            }
            else {
                $self->msg->error("Could not add user");
                $dbh->rollback() if (!$dbh->{AutoCommit});
            }
            $sql->finish();
        }
    }

    $sql = $dbh->prepare(
        'SELECT DISTINCT rolname FROM public.list_users() ORDER BY 1;');
    $sql->execute();
    my $roles = [];

    while ( my $v = $sql->fetchrow() ) {
        push @{$roles}, { rolname => $v };
    }
    $sql->finish();

    $sql = $dbh->prepare(
        'SELECT accname FROM public.list_accounts() ORDER BY 1;');
    $sql->execute();
    my $acc = [];

    while ( my $v = $sql->fetchrow() ) {
        push @{$acc}, { accname => $v };
    }
    $sql->finish();

    $self->stash( roles => $roles, acc => $acc );
    $dbh->disconnect();
    $self->render();
}

sub edit {
    my $self    = shift;
    my $dbh     = $self->database();
    my $rolname = $self->param('rolname');
    my $sql;

    my $method = $self->req->method;
    if ( $method =~ m/^POST$/i ) {    # Add an account to a user
                                      # process the input data
        my $form_data = $self->req->params->to_hash;

        # Check input values
        my $e = 0;
        if ( $form_data->{accname} =~ m/^\s*$/ ) {
            $self->msg->error("Empty account name.");
            $e = 1;
        }
        if ( !$e ) {
            $sql =
                $dbh->prepare( 'GRANT "'
                    . $form_data->{accname}
                    . '" TO "'
                    . $rolname
                    . '"' );
            if ( $sql->execute() ) {
                $self->msg->info("Account added to user");
                $dbh->commit() if (!$dbh->{AutoCommit});
            }
            else {
                $self->msg->error("Could not add account to user");
                $dbh->rollback() if (!$dbh->{AutoCommit});
            }
            $sql->finish();
        }
    }

    $sql = $dbh->prepare(
        "SELECT accname FROM list_users() WHERE rolname = '$rolname' ORDER BY 1;"
    );
    $sql->execute();
    my $acc = [];

    while ( my ($v) = $sql->fetchrow() ) {
        push @{$acc}, { accname => $v };
    }
    $sql->finish();

    $sql = $dbh->prepare(
        "SELECT accname FROM list_accounts() EXCEPT SELECT accname FROM list_users() WHERE rolname = '$rolname' ORDER BY 1;"
    );
    $sql->execute();
    my $allacc = [];

    while ( my ($v) = $sql->fetchrow() ) {
        push @{$allacc}, { accname => $v };
    }
    $sql->finish();

    $self->stash( acc => $acc, allacc => $allacc );
    $dbh->disconnect();
    $self->render();
}

sub delete {
    my $self    = shift;
    my $dbh     = $self->database();
    my $rolname = $self->param('rolname');
    my $sql     = $dbh->prepare("SELECT public.drop_user('$rolname');");
    if ( $sql->execute() ) {
        $self->msg->info("User deleted");
        $dbh->commit() if (!$dbh->{AutoCommit});
    }
    else {
        $self->msg->error("Could not delete user");
        $dbh->rollback() if (!$dbh->{AutoCommit});
    }
    $sql->finish();
    $dbh->disconnect();
    $self->redirect_to('user_list');
}

sub delacc {
    my $self    = shift;
    my $dbh     = $self->database();
    my $rolname = $self->param('rolname');
    my $accname = $self->param('accname');
    my $sql =
        $dbh->prepare( 'REVOKE "' . $accname . '" FROM "' . $rolname . '"' );
    if ( $sql->execute() ) {
        $self->msg->info("Account removed from user");
        $dbh->commit() if (!$dbh->{AutoCommit});
    }
    else {
        $self->msg->error("Could not remove account from user");
        $dbh->rollback() if (!$dbh->{AutoCommit});
    }
    $sql->finish();
    $dbh->disconnect();
    $self->redirect_to('user_edit');
}

sub login {
    my $self = shift;

    # Do not go through the login process if the user is already in
    if ( $self->perm->is_authd ) {
        return $self->redirect_to('site_home');
    }

    my $method = $self->req->method;
    if ( $method =~ m/^POST$/i ) {

        # process the input data
        my $form_data = $self->req->params->to_hash;

        # Check input values
        my $e = 0;
        if ( $form_data->{username} =~ m/^\s*$/ ) {
            $self->msg->error("Empty username.");
            $e = 1;
        }

        if ( $form_data->{password} =~ m/^\s*$/ ) {
            $self->msg->error("Empty password.");
            $e = 1;
        }
        return $self->render() if ($e);

        my $dbh =
            $self->database( $form_data->{username}, $form_data->{password} );
        if ($dbh) {
            my $sql = $dbh->prepare('SELECT is_admin(current_user);');
            $sql->execute();
            my $admin = $sql->fetchrow();
            $sql->finish();
            $dbh->disconnect();
            $self->perm->update_info(
                username => $form_data->{username},
                password => $form_data->{password},
                admin    => $admin );

            return $self->redirect_to('site_home');
        }
        else {
            $self->msg->error("Wrong username or password.");
            return $self->render();
        }
    }
    $self->render();
}

sub profile {
    my $self = shift;
    my $dbh  = $self->database();
    my $sql  = $dbh->prepare(
        'SELECT accname FROM list_users() WHERE rolname = current_user;');
    $sql->execute();
    my $acc = [];
    while ( my $v = $sql->fetchrow() ) {
        push @{$acc}, { acc => $v };
    }
    $sql->finish();
    $dbh->disconnect();
    $self->stash( acc => $acc );
    $self->render();
}

sub logout {
    my $self = shift;

    if ( $self->perm->is_authd ) {
        $self->msg->info("You have logged out.");
    }
    $self->perm->remove_info;
    $self->redirect_to('site_home');
}

sub check_auth {
    my $self = shift;

    # Make the dispatch continue when the user id is found in the session
    if ( $self->perm->is_authd ) {
        return 1;
    }

    $self->redirect_to('user_login');
    return 0;
}

sub check_admin {
    my $self = shift;

    # Make the dispatch continue only if the user has admin privileges
    if ( $self->perm->is_admin ) {
        return 1;
    }

    # When the user has no privileges, do not redirect, send 401 unauthorized instead
    $self->render( 'unauthorized', status => 401 );

    return 0;
}

1;
