#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use lib 'lib';
use Mojo::Redis;

sub crc16 {
   my ($string, $poly) = @_;
   my $crc = 0;
   for my $c ( unpack 'C*', $string ) {
      $crc ^= $c;
      for ( 0 .. 7 ) {
         my $carry = $crc & 1;
         $crc >>= 1;
         $crc ^= $poly if $carry;
      }
   }
   return $crc;
}

helper redis => sub { state $r = Mojo::Redis->new };

get '/' => 'chat';


websocket '/socket' => sub {
    my $self = shift;
    my $pubsub = $self->redis->pubsub;

    my $ip = $self->tx->remote_address;
    $ip = sprintf "%04x", crc16($ip,'132');

    my $cb = $pubsub->listen('chat:example' => sub ($pubsub, $msg) { 
        $msg =~ s/^(\S+)\s(.*)$/$1 <$ip> $2/;
        $self->send($msg);
    });

    $self->inactivity_timeout(3600);
    $self->on(finish => sub { $pubsub->unlisten('chat:example' => $cb) });
    $self->on(message => sub ($self, $msg) { $pubsub->notify('chat:example' => $msg) });
};

app->start;

__DATA__
@@ chat.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mojo::Redis Chat Example</title>
    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Roboto:300,300italic,700,700italic">
    <link rel="stylesheet" href="//cdn.rawgit.com/necolas/normalize.css/master/normalize.css">
    <link rel="stylesheet" href="//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css">
    <style>
      body {
        margin: 3rem 1rem;
      }
      pre {
        padding: 0.2rem 0.5rem;
      }
      .wrapper {
        max-width: 35em;
        margin: 0 auto;
      }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <h1>Mojo::Redis Chat Example</h1>
      <form>
        <label>
          <span>Message:</span>
          <input type="search" name="message" value="" disabled>
        </label>
        <button class="button" disabled>Send message</button>
      </form>
      <h2>Messages</h2>
      <pre id="messages">Connecting...</pre>
    </div>
    %= javascript begin
      var formEl = document.getElementsByTagName("form")[0];
      var inputEl = formEl.message;
      var messagesEl = document.getElementById("messages");
      var messages = [];
      var ws = new WebSocket("<%= url_for('socket')->to_abs %>");
      var hms = function() {
        var d = new Date();
        return [d.getHours(), d.getMinutes(), d.getSeconds()].map(function(v) {
          return v < 10 ? "0" + v : v;
        }).join(":");
      };
      
      function render_chat () {
          messagesEl.innerHTML = messages.join('<br>');
      }

      formEl.addEventListener("submit", function(e) {
        e.preventDefault();
        if (inputEl.value.length) ws.send(hms() + " " + inputEl.value);
        inputEl.value = "";
      });

      ws.onopen = function(e) {
        inputEl.disabled = false;
        document.getElementsByTagName("button")[0].disabled = false;
        messages.unshift(hms() + " &lt;server> Connected.");
        render_chat();
      };

      ws.onmessage = function(e) {
        // messagesEl.innerHTML = e.data.replace(/</g, "&lt;") + "<br>" + messagesEl.innerHTML;
        messages.unshift(e.data.replace(/</g, "&lt;"));
        if (messages.length > 15) {
            messages.pop();
        }
        
        render_chat();
      };
    % end
  </body>
</html>
