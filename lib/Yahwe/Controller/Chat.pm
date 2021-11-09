package Yahwe::Controller::Chat;

use 5.024;
use warnings;

use base 'Yahwe::Controller';

my $cl = 'chat:list';


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

sub socket {
    my $self = shift;
    my $redis = $self->redis;
    my $pubsub = $redis->pubsub;

    my $ip = $self->tx->remote_address;
    $ip = sprintf "%04x", crc16($ip,'666');
    
    
    my $cb = $pubsub->listen('chat:example' => sub { 
        my ($pubsub, $msg) = @_;

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        my $ts = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
        $msg = $ts . ' ' . $msg;
        $msg =~ s/^(\S+)\s(.*)$/$1 <$ip> $2/;
        $self->send($msg);
        
        $redis->db->lpush($cl => $msg);
        if ($redis->db->llen($cl) > 20) {
            $redis->db->rpop($cl);
        }        
    });

    $self->inactivity_timeout(3600);
    $self->on(finish => sub {
        $pubsub->unlisten('chat:example' => $cb)
    });
    
    
    $self->on(message => sub {
        my ($self, $msg) = @_;
        $pubsub->notify('chat:example' => $msg)
    });
};


sub chat {
    my $self = shift;
    my $redis = $self->redis;
    my $chat = $redis->db->lrange($cl, 0, -1);
    $self->stash(chat => $chat);
}

1;
