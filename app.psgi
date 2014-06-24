#!/usr/bin/env perl
use Mojolicious::Lite;
use strict;

use DropCastHero;
use File::Temp;

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
    my $tmp = File::Temp->new;
    $self->param('file')->asset->move_to($tmp->filename);
    open my $tmpfh, '<', $tmp->filename;
    $d->upload($path, $tmpfh);
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
    # TODO: going out of scope is killing the download...
    $self->redirect_to($self->url_for('/')->path('/'));
    my $ua = Mojo::UserAgent->new;
    my $tmp = File::Temp->new;
    $ua->max_redirects(5)->get($url)->res->content->asset->move_to($tmp->filename);
    open my $tmpfh, '<', $tmp->filename;
    $d->upload($path, $tmpfh);
};

get '/' => sub {
    shift->render_static('index.html');
};

app->start;
