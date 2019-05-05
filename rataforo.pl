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
use CGI::Cookie;
use Encode;

my ( $status, $headers, $data );

my $app = sub {

	my ($env) = @_;

	$status  = 200;
	$headers = [];
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

	unless ( grep { $_->[0] eq 'Content-Type' } @{$headers} ) {
		&set_header( 'Content-Type' => 'text/html; charset=utf-8' );
	}

	my $utf8_data = encode_utf8($data);

	return [ $status, $headers, [$utf8_data] ];

};

sub dispatch {

	my ($env) = @_;

	my $data;

	$env->{PATH_INFO} = '/index' if $env->{PATH_INFO} eq '/';

	my ( undef, $method, @params ) = split '/', $env->{PATH_INFO};

	my $req     = Plack::Request->new($env);
	my $session = {};

	my $cookies = CGI::Cookie->parse( $env->{HTTP_COOKIE} );
	if ( $cookies->{session_id}->{value} ) {
		$session->{session_id} = $cookies->{session_id}->{value}->[0];
	}

	my $c = controller->new( $env, $req, $session );

	if ( exists &{"controller::$method"} ) {

		$data = $c->$method(@params);
		my $file = $c->{d}->{template} // $method;

		if ( !defined($data) ) {
			my $out = output->new();
			$data = $out->template( filename => $file, data => $c->{d} );
		}
		elsif ( ref($data) eq 'HASH' ) {
			if ( $data->{redirect} ) {
				$status  = 302;
				$headers = [ Location => $data->{redirect} ];
				$data    = "Location: $data->{redirect}";
			}
			else {
				my $out = output->new();
				$data = $out->template( filename => $file, data => $data );
			}
		}

		if ( $c->{session}->{session_id} ) {
			$c->{m}->touch_session( $c->{session} );
			&save_session( $c->{session}->{session_id} );
		}

	}
	else {
		$data = &error404( { method => $method, params => \@params } );
	}

	return $data;

}

# set or replace a header
sub set_header {

	my ( $key, $value ) = @_;

	push @{$headers}, ( $key => $value );

}

sub index {

	&set_header( 'Content-Type', 'text/plain' );

	return Dumper( \@_ );

}

sub save_session {

	my ($sid) = @_;

	my $c = CGI::Cookie->new(
		-name    => 'session_id',
		-value   => $sid,
		-expires => '+1M',
	);

	&set_header( 'Set-Cookie', $c->as_string );

}

sub error404 {

	my $dump = Dumper( \@_ );
	$status = 404;
	return "<html><body><h1>404 Not Found</h1><pre>$dump</pre></body></html>\n";

}

sub error500 {

	my $dump = Dumper( \@_ );
	$status = 500;
	return "<html><body><h1>500 Internal Server Error</h1><pre>$dump</pre></body></html>\n";

}

