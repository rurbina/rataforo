package output;

use utf8;
use common::sense;
use Template;
use File::Slurper qw(read_text);
use Data::Dumper qw(Dumper);
use Cwd qw(getcwd);

sub new {

	my $self = {};

	bless $self;

}

sub template {

	my ( $s, %arg ) = @_;

	my $output = "";
	my $path   = [ getcwd() . "/themes/default/" ];

	unshift( @{$path}, getcwd() . "/themes/$arg{data}->{site}->{theme}" ) if $arg{data}->{site}->{theme};

	my $tt = Template->new( INCLUDE_PATH => $path, ENCODING => 'utf8' );

	my $fn = $arg{filename} // [ caller(1) ]->[3];
	$fn =~ s/controller:://;
	$fn = "$fn.tt2";

	my $data = { %{ $arg{data} } };

	my $lang = eval {
		use lang_es_mx;
		\&lang_es_mx::l;
	};

	$data->{l} = $lang;

	$data->{dumper} = sub {
		use Data::Dumper qw(Dumper);
		$Data::Dumper::Sortkeys = 1;

		'<pre>' . Dumper( \@_ ) . "</pre>\n";
	};

	$data->{page}->{title} = $arg{title} // $data->{env}->{title};

	my $contents;
	
	$tt->process( 'trail.tt2', { items => $data->{trail} }, \$contents ) if $data->{trail};
	$tt->process( $fn, $data, \$contents ) || die $tt->error(), "\n";

	$data->{contents} = $contents;
	
	$tt->process( '_theme.tt2', $data, \$output );

	return $output;

}

sub html {
	
	my @out = ( '<!DOCTYPE html>', '<html>', @_, '</html>' );

	return join "\n", @out;

}

sub text {

	my $s = shift;
	
	rataforo::set_header( 'Content-Type', 'text/plain' );
	return join "\n", @_;
	
}

1;
