package Yahwe::Controller::Blog;

use 5.024;
use warnings;

use base 'Yahwe::Controller';

use Yahwe::DB;
use POSIX qw/ceil/;


sub blog {
    my $self = shift;
    
    my $page = $self->stash('page') || 1;
    return $self->reply->not_found if $page =~ /\D/;
    return $self->reply->not_found if $page < 1;
    
    my $db = Yahwe::DB->new;
    
    my @posts = $db->select_all(q[SELECT * FROM blog ORDER BY id LIMIT 10 OFFSET ?], ($page - 1) * 10);
    
    my ($count) = $db->select_row(q[SELECT COUNT(1) FROM blog]);
    my $max_page = ceil ($count / 10);
    
    return $self->reply->not_found if $page > $max_page;
    
    $self->render(
        posts       => \@posts,
        max_page    => $max_page,
        page        => $page,
    );
}

1;
