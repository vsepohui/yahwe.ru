package Yahwe::DB;

use 5.024;
use warnings;
use utf8;

use DBI;
use Mojo::Home;
use Yahwe;


sub new {
    my $class = shift;
    
    state $self;

    unless ($self) {
        $self = bless {}, $class;
        $self->connect;
    }
    
    return $self;
}

sub dbh {
    my $self = shift;
    return $self->{dbh};
}

sub connect {
    my $self = shift;
    
    my $home = new Mojo::Home;
    my $path = $home->detect . '/db/yahwe.sqlite3';

    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$path","","", {RaiseError => 1, sqlite_unicode => 1});
    
    return;
}

sub do {
    my $self    = shift;
    my $sql     = shift;
    my @binds   = @_;
    
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    
    return;
}


sub select_all {
	my $self = shift;
    my $q = shift;
    my @binds = @_;
    
    my $sth = $self->dbh->prepare($q);
    $sth->execute(@binds);
    
    my @r;
	while (my $ref = $sth->fetchrow_hashref()) {
		push @r, $ref;
	}
	
	return wantarray ? @r : \@r;
}

sub select_row {
	my $self = shift;
    my $q = shift;
    my @binds = @_;
    
	my $sth = $self->dbh->selectrow_array($q, {}, @binds);
}

1;
