package lang_es_mx;

use utf8;

my %strings = (
	about_user              => 'Breve bio',
	agree_and_register      => 'Aceptar términos y registrarse',
	at_date                 => 'el',
	at_date                 => 'en',
	bad_password => 'Contraseña incorrecta',
	board_index             => 'Foros',
	by_author               => 'Por',
	confirmation_email_sent => 'Sigue las instrucciones en el correo de confirmación para terminar.',
	do_login                => 'Ingresar',
	do_post                 => 'Postear',
	do_reply                => 'Responder',
	email                   => 'Email',
	email_address_already_registered => 'Dirección de email ya registrada previamente',
	invalid_email_address => 'Dirección de email inválida',
	invalid_username => 'Nombre de usuario inválido',
	last_reply              => 'Última respuesta',
	last_thread             => 'Último tema',
	login                   => 'Ingresar',
	login_fail              => 'Contraseña incorrecta',
	login_success           => 'Bienvenido de vuelta',
	logout                  => 'Cerrar sesión',
	member_since            => 'Miembro desde',
	message                 => 'Mensaje',
	name                    => 'Nombre',
	new_reply               => 'Responder',
	new_thread              => 'Nuevo tema',
	new_user_registry       => 'Registro de nuevo usuario',
	num_replies             => '% respuestas',
	password                => 'Contraseña',
	register                => 'Registrarse',
	register_email_body => 'Accede a esta URL para finalizar tu registro:\n\n % \n\nGracias\n\n',
	register_email_subject => 'Registro en sitio',
	site_rules              => 'Términos del sitio',
	subject                 => 'Tema',
	user_not_found          => 'Contraseña incorrecta',
	username                => 'Nombre de usuario',
	username_already_registered => 'Nombre de usuario ya registrado',
	users                   => 'Usuarios',
);

sub l {

	my ( $key, @arg ) = @_;

	my $l = $strings{$key} // qq{Undefined string: $key};

	foreach my $sub (@arg) {
		$l =~ s/(?<!%)%/$sub/;
	}

	return $l;

}

1;
