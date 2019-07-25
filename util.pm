package util;

use utf8;
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
