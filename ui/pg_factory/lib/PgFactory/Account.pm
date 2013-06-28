package PgFactory::Account;

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
    if ( $method =~ m/^POST$/i ) {    # Create a new account
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
                $dbh->prepare( "SELECT public.create_account('"
                    . $form_data->{accname}
                    . "');" );
            if ( $sql->execute() ) {
                $self->msg->info("Account created");
                $dbh->commit() if (!$dbh->{AutoCommit});
            }
            else {
                $self->msg->error("Could not create account");
                $dbh->rollback() if (!$dbh->{AutoCommit});
            }
            $sql->finish();
        }
    }

    $sql = $dbh->prepare(
        'SELECT accname FROM public.list_accounts() ORDER BY 1;');
    $sql->execute();
    my $acc = [];
    while ( my $v = $sql->fetchrow() ) {
        push @{$acc}, { accname => $v };
    }
    $sql->finish();

    $self->stash( acc => $acc );

    $dbh->disconnect();
    $self->render();
}

sub delete {
    my $self    = shift;
    my $dbh     = $self->database();
    my $accname = $self->param('accname');
    my $sql     = $dbh->prepare("SELECT public.drop_account('$accname');");
    if ( $sql->execute() ) {
        $self->msg->info("Account deleted");
        $dbh->commit() if (!$dbh->{AutoCommit});
    }
    else {
        $self->msg->error("Could not delete account");
        $dbh->rollback() if (!$dbh->{AutoCommit});
    }
    $sql->finish();
    $dbh->disconnect();
    $self->redirect_to('account_list');
}

sub delrol {
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
    $self->redirect_to('account_edit');
}

sub edit {
    my $self    = shift;
    my $dbh     = $self->database();
    my $accname = $self->param('accname');
    my $sql;

    my $method = $self->req->method;
    if ( $method =~ m/^POST$/i ) {

        # process the input data
        my $form_data = $self->req->params->to_hash;

        # Check input values
        my $e = 0;
        if ( !$form_data->{existing_username} =~ m/^\s*$/ ) {

            # Add existing user to account
            $sql =
                $dbh->prepare( 'GRANT "' 
                    . $accname 
                    . '" TO "'
                    . $form_data->{existing_username}
                    . '";' );
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
        else {

            # Create new user in this account
            if ( $form_data->{username} =~ m/^\s*$/ ) {
                $self->msg->error("Empty username.");
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
                        . $accname
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
    }

    $sql = $dbh->prepare(
        "SELECT useid,rolname FROM list_users('$accname') ORDER BY 2;");
    $sql->execute();
    my $roles = [];

    while ( my ( $i, $n ) = $sql->fetchrow() ) {
        push @{$roles}, { rolname => $n };
    }
    $sql->finish();

    $sql = $dbh->prepare(
        "SELECT DISTINCT rolname FROM list_users() EXCEPT SELECT rolname FROM list_users('$accname') ORDER BY 1;"
    );
    $sql->execute();
    my $allroles = [];

    while ( my ($v) = $sql->fetchrow() ) {
        push @{$allroles}, { rolname => $v };
    }
    $sql->finish();

    $self->stash( roles => $roles, allroles => $allroles );

    $dbh->disconnect();
    $self->render();
}

1;
