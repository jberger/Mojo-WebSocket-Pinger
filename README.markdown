# Mojo::WebSocket::Pinger

Simple module for pinging over websocket.

```perl

use Mojo::WebSocket::Pinger;

$ua->websocket($url, sub {
  my ($ua, $tx) = @_;
  die 'Handshake failed' unless $tx->is_websocket;

  my $pinger = Mojo::WebSocket::Pinger->new(tx => $tx);

  $pinger->ping_p->then(
    sub { say 'Pong' },
    sub { warn $_[0] },
  );

  $tx->on(finish => sub { undef $pinger });
});

```

# LICENSE

This code is copyright (c) 2019 Joel Berger.
It is released under the same terms as Perl 5.
