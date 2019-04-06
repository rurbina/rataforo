package rataforo;

use utf8;
use common::sense;
use Switch qw(Perl6);
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;
use lib '.';
use controller;
use output;
use Plack::Request;
use Try::Tiny;
use Encode;

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
			$data = &dispatch($env);
		}
		default {
			$status = 404;
			$data   = &error404($env);
		}
	}

	my $utf8_data = encode_utf8($data);
	
	return [ $status, \@{%{$headers}}, [$utf8_data] ];

};

sub dispatch {

	my ($env) = @_;

	my $data;
	
	$env->{PATH_INFO} = '/index' if $env->{PATH_INFO} eq '/';
	
	my ( undef, $method, @params ) = split '/', $env->{PATH_INFO};

	my $req = Plack::Request->new($env);
	my $session;

	my $c = controller->new( $env, $req, \$session );
	my $m = $c->can($method);

	if ( exists &{"controller::$method"} ) {

		$data = $c->$method(@params);
		my $file = $c->{d}->{template} // $method;

		if ( !defined($data) ) {
			my $out = output->new();
			$data = $out->template( filename => $file, data => $c->{d} );
		}
		if ( ref($data) eq 'HASH' ) {
			my $out = output->new();
			$data = $out->template( filename => $file, data => $data );
		}

		&touch_session(\$session);
	}
	else {
		$data = &error404( { method => $method, params => \@params } );
	}

	return $data;
	
}

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

	my $dump = Dumper(\@_);
	$status = 500;
	return "<html><body><h1>500 Internal Server Error</h1><pre>$dump</pre></body></html>\n";

}

sub touch_session {

	my $session = shift;
	
	if ( $session && $$session ) {
		die 'omgdotouch';
	}
	
}

