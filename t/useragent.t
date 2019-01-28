use Mojo::Base -strict;

use Mojolicious;
use Mojo::UserAgent;
use Mojo::WebSocket::Pinger;

use Test::More;

my $app = Mojolicious->new;
$app->routes->websocket('/' => sub {
  my $c = shift;
  $c->on(message => sub { shift->finish });
});

my $ua = Mojo::UserAgent->new;
$ua->server->app($app);

my ($ok, $pinger, $tx);
$ua->websocket_p('/')
  ->then(sub {
    $tx = shift;
    $pinger = Mojo::WebSocket::Pinger->new($tx);
    $pinger->ping_p->then(sub { $ok = 1 });
  })
  ->catch(sub{ warn $_[0] })
  ->wait;

ok $ok, 'got pong';

done_testing;

