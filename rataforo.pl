package rataforo;

use utf8;
use common::sense;
use Switch qw(Perl6);
use Data::Dumper qw(Dumper);
use controller;

my ( $status, $headers, $data );

my $app = sub {

	my ($env) = @_;

	$status  = 200;
	$headers = { 'Content-Type' => 'text/html' };
	$data;

	given ( $env->{PATH_INFO} ) {
		when '/' {
			$env->{PATH_INFO} = '/index';
			next
		}
		when m!^/[^/]+! {

			my ( $method, @params ) = ( $env->{PATH_INFO} =~ m!^/([^/]+)(/[^/]+)*$! );
			map { $_ =~ s!^/!! } @params;

			my $c = controller->new();

			if ( exists &{ "controller::$method" } ) {
				$data = $c->$method(@params) || &error500($method);
			}
			else {
				$data = &error404($method);
			}

		}
		default {
			$status = 404;
			$data   = &error404($env);
		}
	}

	return [ $status, \@{%{$headers}}, [$data] ];

};

# set or replace a header
sub set_header {

	my ( $key, $value ) = @_;

	$headers->{$key} = $value;

}

sub index {

	&set_header( 'Content-Type', 'text/plain' );
	
	return Dumper( \@_ );

}

sub error404 {

	$status = 404;
	return "<html><body><h1>404 Not Found: $_[0]</h1></body></html>\n";

}

sub error500 {

	$status = 500;
	return "<html><body><h1>500 Internal Server Error: $_[0]</h1></body></html>\n";

}
