use strict;
use Test::More;

use_ok 'Plack::Middleware::Icecast::StatusUpdate';

BAIL_OUT 'compile failed' unless Test::More->builder->is_passing;

done_testing;
