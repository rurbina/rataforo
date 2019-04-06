package util;

use Convert::Base64;
use Crypt::ScryptKDF qw(scrypt_hash scrypt_hash_verify);
use Digest::MD5 qw(md5_hex);
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

my $key = 'omgwtfbbq';

sub new {

	my $self = {};

	bless $self;

}

sub encrypt_password {

	my ( $s, $pass, $salt ) = @_;

	my $cypher_hashed = scrypt_hash( $pass, $salt );

	return $cypher_hashed;

}

sub test_password {

	my ( $s, $pass, $hash ) = @_;

	return scrypt_hash_verify( $pass, $hash );

}

1;
