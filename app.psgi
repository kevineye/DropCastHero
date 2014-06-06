#!/usr/bin/env perl
use Mojolicious::Lite;
use strict;

use DropCastHero;

get '/feed/:token' => sub {
    my $self = shift;
    my $token = $self->param('token');
    my $d = DropCastHero->new($token);
    $self->render(text => $d->feed_content, format => 'xml');
};

app->start;
