package Yahwe::Controller::Chat;

use 5.024;
use warnings;

use base 'Yahwe::Controller';


# Try magick code based on some sudden code from habr.com, don't remember author, 
# but thank you guy, you show me, how to work with webscokets (js template, copypasted too)
# Not for resale


my $cl = 'chat:list';


sub socket {
    my $self = shift;
    
    my $ref = $self->req->headers->referer();
    warn $ref;
    #return unless $ref =~ /^https\:\/\/yahwe.kosherny.site\//;
    
    my $redis = $self->redis;
    my $pubsub = $redis->pubsub;

    my $ip = $self->tx->remote_address;
    $ip =~ s/^\d+\.\d+\./*.*./;
    
    
    my $cb = $pubsub->listen('chat:example' => sub { 
        my ($pubsub, $msg) = @_;

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        my $ts = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
        $msg = $ts . ' ' . $msg;
        $msg =~ s/^(\S+)\s(.*)$/$1 <$ip> $2/;
        $self->send($msg);
        
        $redis->db->lpush($cl => $msg);
        if ($redis->db->llen($cl) > 100) {
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
