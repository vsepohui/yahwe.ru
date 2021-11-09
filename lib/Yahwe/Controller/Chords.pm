package Yahwe::Controller::Chords;

use 5.024;
use warnings;

use base 'Yahwe::Controller';

use Mojo::Home;
use Encode;
use open IO => qw{:encoding(UTF-8) :std};
use utf8;


sub chords {
    my $self = shift;
    
    my $home = new Mojo::Home;
    my $dir = $home->detect . '/chords/';
    
    my $d;
    opendir $d, $dir;
    my @files = readdir $d;
    closedir $d;
    
    @files = sort map {Encode::decode('UTF-8', $_)} grep {/^.+\.txt$/} @files;
    
    $self->render(files => \@files);
}

sub song {
    my $self = shift;
    my $song = $self->stash('song');

    my $home = new Mojo::Home;
    my $dir = $home->detect . '/chords/';
    
    my $file = $dir . $song . '.txt';
    
    unless (-f $file) {
        return $self->reply->not_found;
    }
    
    
    my $s = '';
    my $fh;
    open $fh, $file;
    while (my $i = <$fh>) {
        $s .= $i;
    }
    close $fh;
    
    
    $self->render(song => $song, chords => $s);
}

1;
