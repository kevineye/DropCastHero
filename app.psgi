#!/usr/bin/env perl
use Mojolicious::Lite;
use strict;

BEGIN { $ENV{MOJO_MAX_MESSAGE_SIZE} = 0 }

use DropCastHero;
use File::Temp;

sub drop_cast_hero_from_request { # blocks
    my $req = shift;
    my $token = $req->param('token');
    my $d = DropCastHero->new({ token => $token, base => $req->url_for('/')->to_abs });
    return $d;
}

get '/feed/:token' => sub {
    my $self = shift;
    my $d = drop_cast_hero_from_request($self); # blocks
    $self->render(text => $d->feed_content, format => 'xml'); # blocks
};

get '/dl/:token/*path' => sub {
    my $self = shift;
    my $d = drop_cast_hero_from_request($self); # blocks
    my $path = $self->stash('path');
    $self->redirect_to($d->direct_link("/$path")); # blocks
    $self->rendered(302);
};

post '/ul/:token/*path' => { path => '' } => sub { # requires file param in POST body
    my $self = shift;
    my $d = drop_cast_hero_from_request($self); # blocks
    my $path = $self->stash('path') || $self->param('file')->filename;
    my $tmp = File::Temp->new;
    $self->param('file')->asset->move_to($tmp->filename);
    open my $tmpfh, '<', $tmp->filename;
    $d->upload($path, $tmpfh); # blocks
    $self->redirect_to($self->url_for('/')->path('/'));
    $self->rendered(302);
};

my %ua_handles;

post '/grab/:token/*path' => { path => '' } => sub { # requires url param in POST body
    my $self = shift;
    my $d = drop_cast_hero_from_request($self); # blocks
    my $url = $self->param('url');
    my $path = $self->stash('path');
    unless ($path) {
        $url =~ m{/([^/]+?)(?:$|\?|#)};
        $path = $1;
    }
    $self->redirect_to($self->url_for('/')->path('/'));
    $self->rendered(302);

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(5)->get($url => sub {
        my ($ua, $tx) = @_;
        my $tmp = File::Temp->new;
        $tmp->unlink_on_destroy(0);
        $tx->res->content->asset->move_to($tmp->filename);
        open my $tmpfh, '<', $tmp->filename;
        $d->upload($path, $tmpfh); # blocks
        delete $ua_handles{$ua};
    });

    # if $ua goes out of scope, the request is aborted, the callback is called immediately, it all falls apart
    $ua_handles{$ua} = $ua;
};

get '/' => sub {
    shift->render_static('index.html');
};

app->start;
