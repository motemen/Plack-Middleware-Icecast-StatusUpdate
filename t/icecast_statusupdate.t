use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $test = sub {
    my $title = shift;
    return sub {
        my $req = shift;
        my $app = builder {
            enable 'Plack::Middleware::Icecast::StatusUpdate', interval => 16;
            sub {
                my $env = shift;
                ok $env->{'icy.status'} or diag 'got env: ' . explain $env;
                $env->{'icy.status'}->{title} = $title;
                [ 200, [ 'Content-Type' => 'audio/mpeg' ], [ 'x' x 20 ] ];
            };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $res = $test->('foobar')->(GET '/');
    is $res->content, 'x' x 20;
}

{
    my $res = $test->('foobar')->(GET '/', ICY_Metadata => 1);
    is $res->content, ('x' x 16) . "\x02" . q(StreamTitle='foobar';) . ("\0" x 11) . ('x' x 4);
}

done_testing;
