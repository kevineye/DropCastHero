package DropCastHero;
use strict;

use File::Dropbox 'contents';
use JSON 'from_json';

sub new {
    my ($class, $token) = @_;
    my $self = bless {
        dropbox => File::Dropbox->new(
            access_token => $token,
            root => 'sandbox',
            oauth2 => 1
        ),
    }, $class;
    return $self;
}

sub list {
    my ($self) = @_;
    return contents($self->{dropbox});
}

sub link {
    my ($self, $path) = @_;
    return unless $path =~ m{^/};
    my $handle = $self->{dropbox};
    my $dropbox = *$handle{'HASH'};
    my $furl = $dropbox->{'furl'};
    my $url = "https://api.dropbox.com/1/media/$dropbox->{root}$path";
	my $response = $furl->post($url, $dropbox->__headers__);
    if ($response->code == 200) {
        my $meta = from_json($response->content());
        return $meta->{url};
    } else {
        return;
    }
}

sub title_from_filename {
    my ($self, $name) = @_;
    $name =~ s{.*/}{};
    $name =~ s{\.[^.]+$}{};
    $name =~ s{_-}{ }g;
    return ucfirst $name;
}

sub feed_content {
    my ($self, $meta) = @_;
    $meta ||= {};
    $meta->{title} ||= 'DropCastHero';

    my $content = <<XML;
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
    <channel>
        <title>$meta->{title}</title>
XML

    for my $item ($self->list) {
        next unless $item->{mime_type} && $item->{mime_type} =~ m{^audio/|^video};
        my $title = $self->title_from_filename($item->{path});
        my $link = $self->link($item->{path});
        $content .= <<XML;
        <item>
            <title>$title</title>
            <enclosure url="$link" length="" type="$item->{mime_type}" />
            <source url="$link">Download</source>
        </item>
XML
    }

    $content .= <<XML;
    </channel>
</rss>
XML

    return $content;
}

1;
