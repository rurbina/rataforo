package controller;

use output;

sub new {

	my $self = {
		out => output->new(),
	};

	bless $self;

}

sub index {
	...
}

sub board {

	my ( $s, $board_id ) = @_;

	my $board = {
		id => $board_id,
		name => 'test board',
	};
	
	$s->{out}->template( data => { board => $board } );

}

1;
