package GrapherProcess;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # register Helpers plugins namespace
    $self->plugins->namespaces([ "Helpers", @{ $self->plugins->namespaces } ]);

    # setup charset
    $self->plugin( charset => { charset => 'utf8' } );

    # load configuration
    my $config_file = $self->home.'/grapher_process.conf';
    my $config = $self->plugin('JSONConfig' => { file => $config_file });

    # setup secret passphrase
    $self->secret($config->{secret} || 'Xwgr-_d:yGDr+p][Vs7Kk+e3GMmP=c_|s7hvExF=b|4r4^gO|');

    # startup database connection
    $self->plugin('database', $config->{ database } || {} );

    # Load HTML Messaging plugin
    $self->plugin('messages');

    # Load properties helper
    $self->plugin('properties', file => $self->home.'/default_options.json');

    # CGI pretty URLs
    if ($config->{rewrite}) {
	$self->hook(before_dispatch => sub {
			my $self = shift;
			$self->req->url->base(Mojo::URL->new($config->{base_url}));
		    });
    }

    # Router
    my $r = $self->routes;

    # Properties
    $r->route('/properties')->to('properties#defaults')->name('properties_defaults');

    # Categories
    $r->get('/categories')->to('categories#list')->name('categories_list');
    $r->route('/categories/add')->to('categories#add')->name('categories_add');
    $r->route('/categories/:id/edit', id => qr/\d+/)->to('categories#edit')->name('categories_edit');
    $r->route('/categories/:id/remove', id => qr/\d+/)->to('categories#remove')->name('categories_remove');


    # Graphs
    $r->route('/graphs')->to('graphs#list')->name('graphs_list');
    $r->route('/graphs/add')->to('graphs#add')->name('graphs_add');
    $r->route('/graphs/:id', id => qr/\d+/)->to('graphs#show')->name('graphs_show');

    $r->route('/graphs/:id/edit', id => qr/\d+/)->to('graphs#edit')->name('graphs_edit');
    $r->route('/graphs/:id/remove', id => qr/\d+/)->to('graphs#remove')->name('graphs_remove');

    $r->post('/graphs/data')->to('graphs#data')->name('graphs_data');

    # Series configuration
    $r->route('/graphs/:id/series/add', id => qr/\d+/)->to('graphs#series_add')->name('series_add');
    $r->route('/graphs/:id/series/:is/edit', id => qr/\d+/, is => qr/\d+/)->to('graphs#series_edit')->name('series_edit');
    $r->route('/graphs/:id/series/:is/remove', id => qr/\d+/, is => qr/\d+/)->to('graphs#series_remove')->name('series_remove');


}

1;
