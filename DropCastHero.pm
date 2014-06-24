package DropCastHero;
use strict;

use File::Temp; # used by WebService::Dropbox but mistakenly not included
use JSON 'from_json';
use Mojo::URL;
use WebService::Dropbox;

use constant APP_KEY => 'g48hgy6i98byt5y';
use constant APP_SECRET => 'shrw9u0b4l5zi7f';

sub new {
    my ($class, $options) = @_;
    die 'token required' unless $options->{token};
    my ($token, $secret) = split '-', $options->{token};

    my $dropbox = WebService::Dropbox->new({ key => APP_KEY, secret => APP_SECRET });
    $dropbox->root('sandbox');
    $dropbox->access_token($token);
    $dropbox->access_secret($secret);

    my $self = bless {
        access_token => $options->{token},
        dropbox => $dropbox,
    }, $class;

    $self->{base} = Mojo::URL->new($options->{base}) if $options->{base};
    $self->{download_base} = $self->{download_base} || Mojo::URL->new('/dl/');
    $self->{download_base} = $self->{download_base}->to_abs($self->{base}) if $self->{base};

    return $self;
}

sub list {
    my ($self) = @_;
    return @{$self->{dropbox}->metadata('/')->{contents}};
}

sub permanent_link {
    my ($self, $path, $base) = @_;
    return unless $path =~ m{^/};
    return Mojo::URL->new($self->{access_token} . $path)->to_abs($base || $self->{download_base});
}

sub direct_link {
    my ($self, $path) = @_;
    return unless $path =~ m{^/};
	return Mojo::URL->new($self->{dropbox}->media($path)->{url});
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
    my ($self, $filename, $fh) = @_;
    $filename = "/$filename" unless $filename =~ m{^/};
    $self->{dropbox}->files_put_chunked($filename, $fh);
}

1;
