package Yahwe::Controller;

use 5.024;
use warnings;

use base 'Mojolicious::Controller';

use Yahwe::Cache;


sub lang {
    my $self = shift;
    
    my $lang = $self->stash('lang') || 'en';
    
    return $lang;
}

sub cache {
    my $self = shift;
    return $self->stash('cache');
}

sub init_default_vars {
    my $self = shift;
    #die $self->lang;
    $self->stash(
        lang    => $self->lang,
        cache   => new Yahwe::Cache,
    );
}

1;
