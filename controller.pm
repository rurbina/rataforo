package controller;

use output;
use model;

sub new {

	my ( $class, $env ) = @_;

	my $self = {
		out => output->new(),
		m   => model->new(),
		d   => {
			env => $env,
		},
	};

	$self->{d}->{site} = $self->{m}->get_site();

	$env->{title} = $self->{d}->{site}->{title};

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

sub index {

	my ($s) = @_;

	$s->{d}->{boards} = $s->{m}->get_boards();

	$s->set_title( $s->l('board_index') );

	$s->{out}->template( data => $s->{d} );

}

sub board {

	my ( $s, $board_id ) = @_;

	$s->{d}->{board} = $s->{m}->get_board( board_id => $board_id, get_threads => 1 )
	  or die 'board not found';

	$s->set_title( $s->{d}->{board}->{title} );

	$s->{out}->template( data => $s->{d} );

}

sub thread {

	my ( $s, $board_id, $thread_id ) = @_;

	$s->{d}->{thread} = $s->{m}->get_thread( thread_id => $thread_id, get_replies => 1 )
	  or die 'thread not found';

	$s->{d}->{board} = $s->{m}->get_board( board_id => $d->{s}->{thread}->{board_id} );

	$s->{out}->template( data => $s->{d} );

}

1;
