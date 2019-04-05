package rataforo;

use utf8;
use common::sense;
use Switch qw(Perl6);
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;
use lib '.';
use controller;

my ( $status, $headers, $data );

my $app = sub {

	my ($env) = @_;

	$status  = 200;
	$headers = { 'Content-Type' => 'text/html' };
	$data;

	my @trace;
	$env->{trace} = \@trace;

	given ( $env->{PATH_INFO} ) {
		when m!^/[^/]*! {

			$env->{PATH_INFO} = '/index' if $env->{PATH_INFO} eq '/';
			
			my ( $method, @params ) = ( $env->{PATH_INFO} =~ m!^/([^/]+)(/[^/]+)*$! );
			map { $_ =~ s!^/!! } @params;

			push @trace, 'in $env->{PATH_INFO}';

			my $c = controller->new($env);

			if ( exists &{ "controller::$method" } ) {
				$data = $c->$method(@params) || &error500($method);
			}
			else {
				$data = &error404({ method => $method, params => \@params });
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

	my $dump = Dumper(\@_);
	$status = 404;
	return "<html><body><h1>404 Not Found</h1><pre>$dump</pre></body></html>\n";

}

sub error500 {

	$status = 500;
	return "<html><body><h1>500 Internal Server Error: $_[0]</h1></body></html>\n";

}
