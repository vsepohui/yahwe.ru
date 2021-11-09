package Yahwe;

use 5.024;
use warnings;

use base 'Mojolicious';

use HTTP::AcceptLanguage;
use Mojo::Redis;


sub startup {
    my $self = shift;
    
    my $config = $self->plugin('Config');

    $self->secrets($config->{secrets});
    
    
    $self->routes->namespaces(['Yahwe::Controller']);
    $self->controller_class('Yahwe::Controller');
        
    
    $self->init_helpers;
    
    $self->hook(before_dispatch => sub {
        my $c = shift;
        $c->init_default_vars;
    });    

    my $r = $self->routes;
    
    $r = $r->under(sub {
        my ($c) = @_;
        
	    my $lang = $c->req->headers->header('Accept-Language');
	    my $al = new HTTP::AcceptLanguage($lang);

        my $lang2 = 'en';
	    for (qw/ru en/) {
		    if ($al->match($_)) {
                $lang2 = $_;
                last;
            }
	    }
        
        if ($c->url_for !~ /^\/(ru|en)(\/|$)/) {
            my $p = $c->req->params->to_hash;
            my $qs = join '&', map {$_ . '=' . $p->{$_}} keys %$p;
            $c->redirect_to('/' . $lang2 . $c->url_for . '?' .$qs);
            return;
        }
               
        return 1;
    });
    
    $r->get('/')->to('Home#home', lang => 'en');
    $r->get('/ru/')->to('Home#home', lang => 'ru');
    $r->get('/en/')->to('Home#home', lang => 'en');
    
    $r->get('/me')->to('Home#me');
    $r->get('/ru/me')->to('Home#me', lang => 'ru');
    $r->get('/en/me')->to('Home#me');    
    
    $r->get('/unagamma')->to('Unagamma#unagamma', lang => 'en');
    $r->get('/ru/unagamma')->to('Unagamma#unagamma', lang => 'ru');
    $r->get('/en/unagamma')->to('Unagamma#unagamma', lang => 'en');
    
    $r->get('/unagamma/songs')->to('Unagamma#songs', lang => 'en');
    $r->get('/ru/unagamma/songs')->to('Unagamma#songs', lang => 'ru');
    $r->get('/en/unagamma/songs')->to('Unagamma#songs', lang => 'en');

    $r->get('/chat')->to('Chat#chat');
    $r->get('/ru/chat')->to('Chat#chat', lang => 'ru');
    $r->get('/en/chat')->to('Chat#chat');
    
    $r->websocket('/chat/socket')->to('Chat#socket')->name('chat-socket');
    $r->websocket('/ru/chat/socket')->to('Chat#socket')->name('chat-socket-ru');
    $r->websocket('/en/chat/socket')->to('Chat#socket')->name('chat-socket-en');
    

    $r->get('/blog')->to('Blog#blog', lang => 'en');
    $r->get('/ru/blog')->to('Blog#blog', lang => 'ru');
    $r->get('/en/blog')->to('Blog#blog', lang => 'en');
    
    $r->get('/blog/:page')->to('Blog#blog', lang => 'en');
    $r->get('/ru/blog/:page')->to('Blog#blog', lang => 'ru');
    $r->get('/en/blog/:page')->to('Blog#blog', lang => 'en');
    
    $r->get('/releases')->to('Home#releases', lang => 'en');
    $r->get('/ru/releases')->to('Home#releases', lang => 'ru');
    $r->get('/en/releases')->to('Home#releases', lang => 'en');
    
    $r->get('/chords')->to('Chords#chords', lang => 'en');
    $r->get('/ru/chords')->to('Chords#chords', lang => 'ru');
    $r->get('/en/chords')->to('Chords#chords', lang => 'en');
    
    $r->get('/chords/:song')->to('Chords#song', lang => 'en');
    $r->get('/ru/chords/:song')->to('Chords#song', lang => 'ru');
    $r->get('/en/chords')->to('Chords#chords', lang => 'en');
    
    $r->get('/books')->to('Home#books', lang => 'en');
    $r->get('/ru/books')->to('Home#books', lang => 'ru');
    $r->get('/en/books')->to('Home#books', lang => 'en');
    
    $r->get('/photos')->to('Photos#photos', lang => 'en');
    $r->get('/ru/photos')->to('Photos#photos', lang => 'ru');
    $r->get('/en/photos')->to('Photos#photos', lang => 'en');
    
    $r->get('/links')->to('Home#links', lang => 'en');
    $r->get('/ru/links')->to('Home#links', lang => 'ru');
    $r->get('/en/links')->to('Home#links', lang => 'en');
    
    $r->get('/say-hi')->to('Home#say_hi', lang => 'en');
    $r->get('/ru/say-hi')->to('Home#say_hi', lang => 'ru');
    $r->get('/en/say-hi')->to('Home#say_hi', lang => 'en');
    
    $r->get('/donate')->to('Home#donate', lang => 'en');
    $r->get('/ru/donate')->to('Home#donate', lang => 'ru');
    $r->get('/en/donate')->to('Home#donate', lang => 'en');


    $r->get('/feedback')->to('Home#feedback');
    $r->get('/ru/feedback')->to('Home#feedback', lang => 'ru');
    $r->get('/en/feedback')->to('Home#feedback');
    
    $r->get('/mirrors')->to('Home#mirrors');
    $r->get('/ru/mirrors')->to('Home#mirrors', lang => 'ru');
    $r->get('/en/mirrors')->to('Home#mirrors');
    
}

sub init_helpers {
	my $self = shift;

    $self->helper(lurl => sub { 
        my ($c, $str) = @_;
        my $lang = $c->stash('lang') || 'en';
        return '/' . $lang . $str;
    });
    
    $self->helper(_l => sub { 
        my ($c, $str) = @_;
        #use Data::Dumper;
        #die Dumper ($c->config);
        
        if (my $s = $c->config->{i18n}->{$c->stash('lang') || 'en'}->{$str}) {
            
            return $s;
        }
        return $str;
    });    
    
    $self->helper(redis => sub { state $r = Mojo::Redis->new });
}

1;

