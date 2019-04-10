package lang_es_mx;

use utf8;

my %strings = (
	about_user     => 'Brevei bio',
	at_date        => 'el',
	at_date        => 'en',
	board_index    => 'Foros',
	by_author      => 'Por',
	do_login       => 'Ingresar',
	do_post        => 'Postear',
	do_reply       => 'Responder',
	last_reply     => 'Última respuesta',
	last_thread    => 'Último tema',
	login          => 'Ingresar',
	login_fail     => 'Contraseña incorrecta',
	login_success  => 'Bienvenido de vuelta',
	member_since   => 'Miembro desde',
	message        => 'Mensaje',
	name           => 'Nombre',
	new_reply      => 'Responder',
	new_thread     => 'Nuevo tema',
	num_replies    => '% respuestas',
	password       => 'Contraseña',
	subject        => 'Tema',
	user_not_found => 'Contraseña incorrecta',
	username       => 'Nombre de usuario',
);

sub l {

	my ($key, @arg) = @_;

	my $l = $strings{$key} // qq{Undefined string: $key}; 

	foreach my $sub ( @arg ) {
		$l =~ s/(?<!%)%/$sub/;
	}

	return $l;

}

1;
