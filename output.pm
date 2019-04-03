package output;

use Template;
use File::Slurp qw(read_file);
use Data::Dumper qw(Dumper);
use Cwd qw(getcwd);

sub new {

	my $self = {};

	bless $self;

}

sub template {

	my ( $s, %arg ) = @_;

	my $output = "";
	my $path   = getcwd() . "/theme_default/";

	my $tt = Template->new(
		INCLUDE_PATH => $path,
	);

	my $fn = $arg{filename} // [ caller(1) ]->[3];
	$fn =~ s/controller:://;
	$fn = "$fn.template";

	my $data   = { %{ $arg{data} } };

	$tt->process( $fn, $data, \$output ) || return $s->text( "template error", $tt->error );

	return $output;

}

sub html {

	my @out = ( '<!DOCTYPE html>', '<html>', @out, '</html>' );

	return join "\n", @out;

}

sub text {

	my $s = shift;
	
	rataforo::set_header( 'Content-Type', 'text/plain' );
	return join "\n", @_;
	
}

1;
