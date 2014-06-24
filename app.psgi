#!/usr/bin/env perl
use Mojolicious::Lite;
use strict;

use DropCastHero;

sub drop_cast_hero_from_request {
    my $req = shift;
    my $token = $req->param('token');
    my $d = DropCastHero->new({ token => $token, base => $req->url_for('/')->to_abs });
    return $d;
}

get '/feed/:token' => sub {
    my $self = shift;
    my $d = drop_cast_hero_from_request($self);
    $self->render(text => $d->feed_content, format => 'xml');
};

get '/dl/:token/*path' => sub {
    my $self = shift;
    my $d = drop_cast_hero_from_request($self);
    my $path = $self->stash('path');
    $self->redirect_to($d->direct_link("/$path"));
};

post '/ul/:token/*path' => { path => '' } => sub { # requires file param in POST body
    my $self = shift;
    my $d = drop_cast_hero_from_request($self);
    my $path = $self->stash('path') || $self->param('file')->filename;
    $d->upload($path, $self->param('file')->slurp);
    $self->redirect_to($self->url_for('/')->path('/'));
};

post '/grab/:token/*path' => { path => '' } => sub { # requires url param in POST body
    my $self = shift;
    my $d = drop_cast_hero_from_request($self);
    my $url = $self->param('url');
    my $path = $self->stash('path');
    unless ($path) {
        $url =~ m{/([^/]+?)(?:$|\?|#)};
        $path = $1;
    }
    $self->redirect_to($self->url_for('/')->path('/'));
    my $ua = Mojo::UserAgent->new;
    my $data = $ua->max_redirects(5)->get($url)->res->content->asset->slurp;
    $d->upload($path, $data);
};

get '/' => sub {
    shift->render_static('index.html');
};

app->start;
