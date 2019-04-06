package controller;

use common::sense;
use output;
use model;
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

sub new {

	my ( $class, $env, $req, $ses ) = @_;

	my $self = {
		out => output->new(),
		m   => model->new(),
		d   => {
			env => $env,
			trail => undef,
		},
		r => $req,
		s => $ses,
	};

	$self->{d}->{site} = $self->{m}->get_site();

	$env->{title} = $self->{d}->{site}->{title};

	$self->{m}->check_session($ses);
	
	bless $self;

}

sub l {

	my ( $s, $key ) = @_;
	use lang_es_mx;

	&lang_es_mx::l($key);

}

sub set_title {

	my ( $s, $title ) = @_;

	$s->{d}->{env}->{title} = join ' :: ', $title, $s->{d}->{site}->{title};

}

sub push_trail {

	my ( $s, @items ) = @_;

	if ( !$s->{d}->{trail} ) {
		$s->{d}->{trail} = [
			{
				title => $s->{d}->{site}->{title},
				href  => '/',
			},
		];
	}

	push @{ $s->{d}->{trail} }, @items;

}

sub index {

	my ($s) = @_;

	$s->{d}->{boards} = $s->{m}->get_boards();

	$s->set_title( $s->l('board_index') );

	return;

}

sub board {

	my ( $s, $board_id ) = @_;

	$s->{d}->{board} = $s->{m}->get_board( board_id => $board_id, get_threads => 1 )
	  or die 'board not found';

	$s->set_title( $s->{d}->{board}->{title} );
	$s->push_trail( { href => qq{/board/$board_id}, title => $s->{d}->{board}->{title} } );

	return;

}

sub thread {

	my ( $s, $board_id, $thread_id ) = @_;

	$s->{d}->{thread} = $s->{m}->get_thread( thread_id => $thread_id, get_replies => 1 )
	  or die 'thread not found';

	$s->{d}->{board} = $s->{m}->get_board( board_id => $s->{d}->{thread}->{board_id} );

	$s->push_trail(
		{ href => qq{/board/$board_id}, title => $s->{d}->{board}->{title} },
		{ href => qq{/thread/$board_id/$thread_id}, title => $s->{d}->{thread}->{subject} },
	);

	return;

}

sub login {

	return;

}

sub do_login {

	my ($s) = @_;
	my $p = $s->{r}->parameters();

	my $status = $s->{m}->login( user_id => $p->{user_id}, passwd => $p->{passwd} );

	if ( $status eq 'ok' ) {
		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('login_success') };
	}
	else {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l('login_error') };
	}

	$s->{d}->{template} = 'index';
	$s->index();

	return;

}

sub new_thread {

	my ($s) = @_;

	my $p = $s->{r}->parameters();

	return $s->dumper( $s->{r}->parameters() );

}

sub dumper {

	my ( $s, $data ) = @_;

	$s->{d}->{data} = $data;

	$s->{out}->template( filename => 'dumper', title => 'Dumper', data => $s->{d} );

}

1;
