package Yahwe::Controller::Home;

use 5.024;
use warnings;

use base 'Yahwe::Controller::Unagamma';

use Yahwe::Controller::Unagamma;
use HTTP::AcceptLanguage;


sub home {
    my $self = shift;
    $self->unagamma(mini => 1);
    $self->render;
}

sub me {
    my $self = shift;
    $self->render;
}

sub releases {
    my $self = shift;
    $self->render;
}

sub books {
    my $self = shift;
    $self->render;
}

sub links {
    my $self = shift;
    $self->render;
}

sub say_hi {
    my $self = shift;
    $self->render;
}

sub donate {
    my $self = shift;
    $self->render;
}

sub feedback {
    my $self = shift;
    $self->render;
}

sub mirrors {
    my $self = shift;
    $self->render;
}

1;
