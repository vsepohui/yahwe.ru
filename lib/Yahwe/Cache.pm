package Yahwe::Cache;

use 5.024;
use warnings;
use utf8;

use Cache::Memcached::Fast;


sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub set {
    my $self = shift;
    $self->memd->set(@_);
}

sub get {
    my $self = shift;
    $self->memd->get(@_);
}


sub memd {
    state $memd = new Cache::Memcached::Fast({
        servers => [ { address => 'localhost:11211', weight => 1 } ],
        namespace => 'yahwe:',
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 1,
        compress_threshold => 100_000,
        compress_ratio => 0.9,
        compress_methods => [ \&IO::Compress::Gzip::gzip,
                              \&IO::Uncompress::Gunzip::gunzip ],
        max_failures => 3,
        failure_timeout => 2,
        ketama_points => 150,
        nowait => 1,
        hash_namespace => 1,
        serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
        utf8 => 1,
        max_size => 512 * 1024,
    });
    return $memd;
}
 
1;
