package output;

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
	my $path   = getcwd() . "/theme_default/";

	my $tt = Template->new( INCLUDE_PATH => $path, );

	my $fn = $arg{filename} // [ caller(1) ]->[3];
	$fn =~ s/controller:://;
	$fn = "$fn.template";

	my $data = { %{ $arg{data} } };

	my $lang = eval {
		use lang_es_mx;
		\&lang_es_mx::l;
	};

	$data->{l} = $lang;

	$data->{dumper} = sub {
		use Data::Dumper qw(Dumper);
		$Data::Dumper::Sortkeys = 1;

		Dumper \@_;
	};

	$data->{page}->{title} = $arg{title} // $data->{env}->{title};

	$tt->process( 'header.template', $data, \$output ) || return $s->text( "template error", $tt->error );
	$tt->process( $fn, $data, \$output ) || return $s->text( "template error", $tt->error );
	$tt->process( 'footer.template', $data, \$output ) || return $s->text( "template error", $tt->error );

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
