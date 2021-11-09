package Yahwe::Controller::Photos;

use 5.024;
use warnings;

use base 'Yahwe::Controller';

use Mojo::Home;


sub photos {
    my $self = shift;
    
    my $home = new Mojo::Home;
    my $dir = $home->detect . '/public/i/photos/';
    
    
    my @files;
    
    my $dh;
    opendir $dh, $dir;
    while (my $s = readdir($dh)) {
        if ($s =~ /^\d+?\.jpg$/) {
            $s =~ s/\D//g;
            push @files, $s;
        }
    }
    closedir $dh; 
    
    @files = sort {$a <=> $b} @files;
    
    $self->render(files => \@files);
}

1;
