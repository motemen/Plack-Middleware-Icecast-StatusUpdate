use strict;
use warnings;
use lib 'lib';
use Plack::Builder;
use Plack::Request;
use AnyEvent;
use AnyEvent::Util;
use File::Find::Rule;
use MP3::Info;

my $dir = $ENV{MP3_DIR} || '.';
my @files = File::Find::Rule->file->name('*.mp3')->in($dir);

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    $env->{'psgi.streaming'} or die 'streaming feature required';

    my @files = @files;
    return sub {
        my $respond = shift;
        my $writer = $respond->([ 200, [ 'Content-Type' => 'audio/mpeg' ] ]);

        my $next; $next = sub {
            my $file = shift @files or return $writer->close;
            warn "$file\n";

            my $info = MP3::Info->new($file);
            $env->{'icy.status'}->{title} = $info && $info->title || '(unknown)';

            my $guard = guard \&$next;

            open my $fh, '<', $file;
            my $w; $w = AnyEvent->io(
                fh => $fh,
                poll => 'r',
                cb => sub {
                    if (read $fh, my $buf, 4096) {
                        $writer->write($buf);
                    } else {
                        undef $w;
                        undef $guard;
                    }
                }
            )
        };
        $next->();
    };
};

use Plack::Loader;
Plack::Loader->load('AnyEvent::HTTPD', port => 5000)->run(
    builder {
        enable 'Plack::Middleware::Icecast::StatusUpdate';
        $app;
    }
);
