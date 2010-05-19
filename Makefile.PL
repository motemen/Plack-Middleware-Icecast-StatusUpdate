use inc::Module::Install;

name 'Plack-Middleware-Icecast-StatusUpdate';

requires 'Plack';

tests 't/*.t';

test_requires 'Test::More';

auto_include;
WriteAll;
