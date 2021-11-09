package Yahwe::Controller::Unagamma;

use 5.024;
use warnings;

use base 'Yahwe::Controller::Chat';

use Mojo::Home;
use Mojo::DOM;
use URI::Escape qw(uri_unescape);
use Encode qw(encode decode);
use utf8;


sub unagamma {
    my $self = shift;
    $self->songs(@_);
    $self->chat(@_);
}

sub _open_xml {
    my $self = shift;
    my $path = shift;
    
    my ($fi, $s);
    open $fi, $path;
    while (my $i = <$fi>) {
        $s .= $i;
    }
    close $fi;
    
    $s = Encode::decode('UTF-8', $s);
    
    return $s;
}

sub _process_feed {
    my $self = shift;
    my $file = shift;
    my $proc = shift;
    
    state $cache = {};
    
    unless ($cache->{$file}) {
        #warn "no cache $file";
        $cache->{$file}->{m} = -M $file;
        my $s = $self->_open_xml($file);
        return $cache->{$file}->{s} = [$proc->($s)];
    } else {
        #warn "has cache $file";
        if ($cache->{$file}->{m} != -M $file) {
            #warn "rewrite cache $file";
            my $s = $self->_open_xml($file);
            return $cache->{$file}->{s} = [$proc->($s)];
        } else {
            #warn "use cache $file";
            return $cache->{$file}->{s};
        }
    }
}

sub _decode_url {
    my $self = shift;
    my $url = shift;
    
    my $i = uri_unescape($url);
    $i = decode('UTF-8', $i);
    $i =~ s/\+/ /g;
    
    $i =~ s/\&amp\;/\&/g;
    
    return $i;
}

sub _process_xml_main {
    my $self = shift;
    my $mini = shift;
    my $xml  = shift;
    
    my $feed = Mojo::DOM->new($xml);
    $feed = $feed->find('.chartlist-row')->join("\n");
    
    $feed =~ s/[ \t]+/ /g;
    $feed =~ s/\n /\n/g;
    $feed =~ s/\n+/\n/g;
    $feed = [split /chartlist-row/, join "\n", $feed];
    
    
    my @feed;
    
    my $cnt = 0;
    for my $f (@$feed) {
        if ($f =~ / href\=\"\/music\/([^\/]+)\/[^\/]+\/([^\/"]+)\"/) {
            my $i = $self->_decode_url("$1 - $2");
            my ($ts) = $f =~ /chartlist-timestamp.+?\<span[^\>]+\>\s*(.+?)\s*\<\/span\>/s;
            if ($ts) {
                $ts =~ s/\<[^\>]+\>//g;
                push @feed, [$i, $ts];
                last if $mini && $cnt >= 4;
                $cnt ++;
            }
            
        }
    }
    
    return @feed;
}


sub _process_xml_library {
    my $self = shift;
    my $xml = shift;
    
    my $feed = Mojo::DOM->new($xml);
    $feed = $feed->find('.chartlist-row')->join("\n");
    
    $feed =~ s/[ \t]+/ /g;
    $feed =~ s/\n /\n/g;
    $feed =~ s/\n+/\n/g;
    
    $feed = [split /chartlist\-row/, join "\n", $feed];
    #die $feed;
    
    my @feed;
    
    for my $f (@$feed) {
        if ($f =~ / href\=\"\/music\/([^\/]+)\/[^\/]+\/([^"\/]+)\"/) {
            my $i = $self->_decode_url("$1 - $2");
            my ($ts) = $f =~ /chartlist-timestamp.+?\<span[^\>]+\>\s*(.+?)\s*\<\/span\>/s;
            $ts =~ s/\<[^\>]+\>//g;
            push @feed, [$i, $ts];
        }
    }
    
    return @feed;
}

sub _get_artist_info {
    my $self = shift;
    my $artist = shift;
    my $lang = $self->stash('lang');    
    
    use Net::LastFM;
    my $lastfm = Net::LastFM->new(
        api_key    => '79958d2a80cf5e758d233c298681172c',
        api_secret => 'b72f09aa073e6d1cd19c26eec31cf4bb',
    );

    my $data = $lastfm->request_signed(
        method => 'artist.getInfo',
        artist => $artist,
        lang => $lang,
    );

    my $bio  = $data->{artist}->{bio}->{content};
    my $tags = [map {$_->{name}} @{$data->{artist}->{tags}->{tag} || []}];
    my @bio = split /\s+/, $bio;
    my @s;
    for (0..$#bio) {
        push @s, $bio[$_];
        last if length (join ' ', @s) >= 400;
    }
    my $short_bio = join ' ', @s;
    
    return {
        bio         => $bio,
        short_bio   => $short_bio,
        tags        => $tags,
    };
}


sub get_artist_info {
    my $self    = shift;
    my $artist  = shift;
    my $lang    = shift;
    
    my $key = $artist . ':' . $lang;
    
    if (my $d = $self->cache->get($key)) {
        return $d;        
    }
   
    my $d = $self->_get_artist_info($artist);
    $self->cache->set($key => $d);
    return $d;
}

sub songs {
    my $self = shift;
    my %opts = (mini => 0, @_);
    
    my $mini = $opts{mini};
    $mini = 1 if $self->param('mini');

    my $home = new Mojo::Home;
    my $dir = $home->detect . '/db/';
    
    my $feed_1 = $self->_process_feed($dir . 'lastfm.xml', sub {$self->_process_xml_main($mini, shift)});


    my $track = $feed_1->[0]->[0];
    my ($artist, $song) = $track =~ /^([^-]+) - (.+)$/;
    
    
    my $info;
    
    eval {
        $info = $self->get_artist_info($artist, $self->lang);
        unless ($info->{bio} && $self->lang eq 'ru') {
            $info = $self->get_artist_info($artist, 'en');
        }
    };
   
    $self->stash(
        feed    => $feed_1,
        %$info,
    );
}

1;
