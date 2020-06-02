package util;

use utf8;
use common::sense;
use File::Slurper qw(write_text read_text);
use Switch qw(Perl6);
use Convert::Base64;
use Crypt::ScryptKDF qw(scrypt_hash scrypt_hash_verify);
use Digest::MD5 qw(md5_hex);
use CommonMark;
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

my $key = 'omgwtfbbq';

sub new {

	my $self = {};

	bless $self;

}

sub encrypt_password {

	my ( $s, $pass ) = @_;

	my $cypher_hashed = scrypt_hash($pass);

	return $cypher_hashed;

}

sub test_password {

	my ( $s, $pass, $hash ) = @_;

	return scrypt_hash_verify( $pass, $hash );

}

sub htmlize {

	my ( $s, $message, %arg ) = @_;

	my $html;
	$arg{lang} //= 'cmark';

	given $arg{lang}{
		when 'raw' {
			$html = $message;
		}
		when 'cmark' {
			$html = CommonMark->markdown_to_html( $message, CommonMark::OPT_VALIDATE_UTF8 );
		}
	};

	return $html;

}

sub sanitize {

	my ( $s, $value ) = @_;

	$value =~ s/\s+$//g;

	return $value;
	
}

sub sanitize_hash {

	my ( $s, $hashref, %arg ) = @_;

	my $sane = {};
	
	foreach my $key ( keys %{$hashref} ) {
		next if $arg{keys} && ! grep { $_ eq $key } @{$arg{keys}};
		$sane->{$key} = sanitize( $hashref->{$key} );
	}

	return $sane;
	
}

sub validate_input {

	my ( $s, %arg ) = @_;

	my %valid;

	my %functions = (
		optional  => sub { return 1; },
		required  => sub { $_[0] =~ /.+/ ? 1 : undef },
		minlength => sub { length( $_[0] ) >= $_[1] },
		maxlength => sub { length( $_[0] ) <= $_[1] },
		email     => sub { $_[0] =~ m/^[\S_.-]+\@[\S.-]+$/ ? 1 : undef },
		username  => sub { $_[0] =~ m/^[a-z][a-z0-9_+-]{3,32}$/ ? 1 : undef },
	);

	foreach my $key ( keys %{ $arg{values} } ) {

		my $value = $arg{input}->{$key};
		$value =~ s/^\s+|\s+$//g;

		foreach my $check ( @{ $arg{values}->{$key} } ) {
			my $sub = ref($check) eq 'ARRAY' ? shift( @{$check} ) : $check;

			if ( !$functions{$sub}( $value, ( ref($check) eq 'ARRAY' ) ? @{$check} : () ) ) {
				die join( '_', 'validation_failed', $sub, $key ) . ' ' . Dumper $value;
			}

			$valid{$key} = $value;
		}

	}

	return %valid;

}

sub htmlize_file {

	my ( $s, $filename ) = @_;

	return $s->htmlize( read_text($filename) );

}

sub assert_session {

	my ( $s, $session ) = @_;

	die 'session_required' unless $session->{user}->{user_id};
	die 'user_disabled' if $session->{user}->{disabled};

	return 1;

}

1;
