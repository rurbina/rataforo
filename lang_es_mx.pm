package lang_es_mx;

my %strings = (
	new_thread => 'Nuevo tema',
	do_post    => 'Postear',
	board_index => 'Foros',
);

sub l {

	my $key = shift;

	return $strings{$key} // qq{Undefined string: $key};
	
}

1;
