package Plack::Middleware::Icecast::StatusUpdate;
use strict;
use warnings;
no  warnings 'uninitialized';
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(interval);
use Plack::Util;
use POSIX qw(ceil);

use constant DEFAULT_INTERVAL => 16_000;

sub call {
    my ($self, $env) = @_;

    $env->{'icy.status'} = {};

    my $res = $self->app->($env);

    my $interval = $env->{'icy.metaint'} || $self->interval || DEFAULT_INTERVAL;

    $self->response_cb($res, sub {
        my $res = shift;

        if (!$env->{HTTP_ICY_METADATA}) {
            return;
        }

        my $h = Plack::Util::headers($res->[1]);
        $h->push('icy-metaint', $interval);

        if (!$h->exists('Content-Length')) {
            my $int = $interval;
            return sub {
                my $data = shift;
                return unless defined $data;

                my $buf = '';
                while (length($data) >= $int) {
                    $buf .= substr $data, 0, $int, '';
                    my $meta = qq(StreamTitle='$env->{'icy.status'}->{title}');
                    my $len = ceil(length($meta) / 16);
                    $buf .= chr($len) . $meta . ("\x00" x (16 * $len - length $meta));
                    $int = $interval;
                }
                $buf .= $data;
                $int -= length($data);
                $int ||= $interval;

                return $buf;
            };
        }
    });
}

1;
