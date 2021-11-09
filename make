#!/usr/bin/perl

use 5.024;
use warnings;
use experimental 'smartmatch';

my $cmd = $ARGV[0] || 'help';
$cmd =~ s/\W//g;

my $routes = [
    [[qw/u up update/],     \&update],
    [[qw/p pack/],          \&pack],
    [[qw/t thumbs/],        \&thumbs],
    [[qw/b blog/],          \&blog],
    [[qw/w www/],           \&www],
    [[qw/l lastfm/],        \&lastfm],
    [[qw/make/],            \&make],
    [[qw/h help/],          \&help],
];

(map {$_->[1]->()} grep {$cmd ~~ $_->[0]} @$routes) or help();
exit();


sub help {
    say "Usage:";
    say "\tmake update | up | u     Git pull \& reload www-server";
    say "\tmake pack | p            Pack static (js&css)";
    say "\tmake thumbs | t          Update thumbs";
    say "\tmake blog | b            Update blog";
    say "\tmake www | w             Reload www-server (hypnotoad)";
    say "\tmake lastfm | l          Update last.fm music feed";
    say "\tmake make                Rewrite Makefile";
    say "\tmake help | h            Show help";
}

sub update {
    ex('git pull');
    ex('./make www');
}

sub pack {
    ex('cat public/css/bootstrap.min.css public/css/style.css public/css/player.css public/css/fontawesome/all.css > public/css/yahwe.css');
    ex('cat public/js/jquery-3.6.0.min.js public/js/popper.min.js public/js/bootstrap.bundle.min.js public/js/clipboard.js public/js/player.js > public/js/yahwe.js');
    ex('java  -jar etc/yuicompressor-2.4.8.jar public/css/yahwe.css  > public/css/yahwe.min.css');
    ex('uglifyjs public/js/yahwe.js > public/js/yahwe.min.js');
    ex('uglifyjs public/js/lightbox-plus-jquery.min.js public/js/masonry.pkgd.min.js public/js/imagesloaded.pkgd.min.js > public/js/yahwe-photos.min.js');
}

sub thumbs {
    ex(q[find ./public/i/photos/ -maxdepth 1 -iname "*.jpg"|grep -v -P '_\d+\.jpg' | perl -M5.024 -n -e 'state $i = 0 ; $i ++ ;chomp; my $a = my $b = my $f = $_; $b =~ s/(\d+\.jpg)$/_$1/; $f =~ s/^.*?(\d+\.jpg)$/$1/; say "Process $i"; system qq[convert -resize 270x $a $b] unless -f $b']);
}

sub blog {
    ex('./script/update-blog');;
}

sub www {
    ex('hypnotoad script/yahwe');
}

sub lastfm {
    ex('wget https://www.last.fm/user/yoni_yoni_yoni -q -O ./db/lastfm.xml.tmp');
    ex('mv ./db/lastfm.xml.tmp ./db/lastfm.xml');
    ex('./script/update-radio-cover');
}

sub make {
    my $fo;
    open $fo, '>Makefile';
    
    my $rule = sub {
        my $cmd = shift;
        print $fo "$cmd:\n";
        print $fo "\t" . '@./make $@' . "\n\n";
    };
    
    $rule->('all');
    for (@$routes) {
        $rule->($_) for @{$_->[0]};
    }
    close $fo;
}

sub ex {
    my $cmd = shift;
    print `$cmd`;
}

1;
