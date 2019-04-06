package lang_es_mx;

use utf8;

my %strings = (
	new_thread     => 'Nuevo tema',
	do_post        => 'Postear',
	board_index    => 'Foros',
	login          => 'Ingresar',
	username       => 'Nombre de usuario',
	password       => 'Contraseña',
	do_login       => 'Ingresar',
	by_author      => 'Por',
	at_date        => 'en',
	user_not_found => 'Contraseña incorrecta',
	login_success  => 'Bienvenido de vuelta',
	login_fail     => 'Contraseña incorrecta',
);

sub l {

	my $key = shift;

	return $strings{$key} // qq{Undefined string: $key};

}

1;
