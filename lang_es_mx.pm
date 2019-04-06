package lang_es_mx;

use utf8;

my %strings = (
	new_thread => 'Nuevo tema',
	do_post    => 'Postear',
	board_index => 'Foros',
	login => 'Ingresar',
	username => 'Nombre de usuario',
	password => 'Contraseña',
	do_login => 'Ingresar',
	by_author => 'Por',
	at_date => 'en',
);

sub l {

	my $key = shift;

	return $strings{$key} // qq{Undefined string: $key};
	
}

1;
