package DropCastHero;
use strict;

use File::Dropbox qw(contents putfile);
use JSON 'from_json';
use Mojo::URL;

sub new {
    my ($class, $options) = @_;
    die 'token required' unless $options->{token};
    my $self = bless {
        access_token => $options->{token},
        dropbox => File::Dropbox->new(
            access_token => $options->{token},
            root => 'sandbox',
            oauth2 => 1
        ),
    }, $class;
    $self->{base} = Mojo::URL->new($options->{base}) if $options->{base};
    $self->{download_base} = $self->{download_base} || Mojo::URL->new('/dl/');
    $self->{download_base} = $self->{download_base}->to_abs($self->{base}) if $self->{base};
    return $self;
}

sub list {
    my ($self) = @_;
    return contents($self->{dropbox});
}

sub permanent_link {
    my ($self, $path, $base) = @_;
    return unless $path =~ m{^/};
    return Mojo::URL->new($self->{access_token} . $path)->to_abs($base || $self->{download_base});
}

sub direct_link {
    my ($self, $path) = @_;
    return unless $path =~ m{^/};
    my $handle = $self->{dropbox};
    my $dropbox = *$handle{'HASH'};
    my $furl = $dropbox->{'furl'};
    my $url = "https://api.dropbox.com/1/media/$dropbox->{root}$path";
	my $response = $furl->post($url, $dropbox->__headers__);
    if ($response->code == 200) {
        my $meta = from_json($response->content());
        return Mojo::URL->new($meta->{url});
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
        my $link = $self->permanent_link($item->{path});
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

sub upload {
    my ($self, $filename, $data) = @_;
    $filename = "/$filename" unless $filename =~ m{^/};
    putfile($self->{dropbox}, $filename, $data) or die $!;
}

1;
