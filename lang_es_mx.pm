package lang_es_mx;

use utf8;

my %strings = (

	about_user                       => 'Breve bio',
	agree_and_register               => 'Aceptar términos y registrarse',
	at_date                          => 'el',
	at_date                          => 'en',
	bad_password                     => 'Contraseña incorrecta',
	board_counts                     => '% temas<br>% respuestas',
	board_id                         => 'ID foro',
	board_index                      => 'Foros',
	boards                           => 'Foros',
	by_author                        => 'Por',
	change_password                  => 'Cambiar contraseña',
	confirmation_email_sent          => 'Sigue las instrucciones en el correo de confirmación para terminar.',
	control_panel                    => 'Panel de control',
	description                      => 'Descripción',
	do_change_password               => 'Actualizar',
	do_login                         => 'Ingresar',
	do_post                          => 'Postear',
	do_reply                         => 'Responder',
	email                            => 'Email',
	email_address_already_registered => 'Dirección de email ya registrada previamente: %',
	error_new_password_is_invalid    => 'La nueva contraseña es inválida, agrega más caracteres e intenta de nuevo',
	error_not_logged_in              => 'Es necesario ingresar con nombre de usuario y contraseña para ver esta pantalla',
	error_passwords_do_not_match     => 'La confirmación de contraseña no coincide, verifica e intenta de nuevo',
	general_settings                 => 'Ajustes generales',
	gravatar_email                   => 'Email Gravatar',
	invalid_email_address            => 'Dirección de email inválida',
	invalid_preregister_hash         => 'El hash de preregistro utilizado expiró o ya fue utilizado',
	invalid_username                 => 'Nombre de usuario inválido',
	last_reply                       => 'Última respuesta',
	last_thread                      => 'Último tema',
	logged_in_as                     => 'Sesión iniciada: <b>%</b>',
	logged_out                       => 'Sesión finalizada',
	login                            => 'Ingresar',
	login_fail                       => 'Contraseña incorrecta',
	login_success                    => 'Bienvenido de vuelta',
	logout                           => 'Cerrar sesión',
	member_since                     => 'Miembro desde',
	message                          => 'Mensaje',
	modify_user                      => 'Modificar usuario',
	name                             => 'Nombre',
	new_password                     => 'Nueva contraseña',
	new_replies                      => 'Nuevas respuestas',
	new_reply                        => 'Responder',
	new_thread                       => 'Nuevo tema',
	new_user_registry                => 'Registro de nuevo usuario',
	num_replies                      => '% respuestas',
	old_password                     => 'Contraseña anterior',
	password                         => 'Contraseña',
	password_updated                 => 'Contraseña actualizada',
	register                         => 'Registrarse',
	register_complete                => 'Reigstro completado con éxito',
	register_email_subject           => 'Registro en sitio',
	replies                          => 'Respuestas',
	retype_password                  => 'Confirmar contraseña',
	set_your_password_to_finish      => 'Registro completado, crea una contraseña para terminar',
	site_rules                       => 'Términos del sitio',
	sort_index                       => 'Orden',
	start                            => 'Inicio',
	subject                          => 'Tema',
	threads                          => 'Temas',
	title                            => 'Título',
	user_not_found                   => 'Contraseña incorrecta',
	username                         => 'Nombre de usuario',
	username_already_registered      => 'Nombre de usuario ya registrado',
	users                            => 'Usuarios',

	first_page    => '«',
	previous_page => '‹',
	next_page     => '›',
	last_page     => '»',

	setting_dark_mode                  => 'Modo oscuro',
	setting_description                => 'Descripción del sitio',
	setting_email_from                 => 'Origen de correo electrónico',
	setting_language                   => 'Idioma',
	setting_recaptcha_key              => 'ReCaptcha Key',
	setting_recaptcha_secret           => 'ReCaptcha Secret',
	setting_register_instructions      => 'Instrucciones de registro',
	setting_require_email_confirmation => 'Requerir confirmación por correo electrónico',
	setting_site_url                   => 'URL del sitio',
	setting_theme                      => 'Tema visual',
	setting_threads_per_page           => 'Temas por página',
	setting_title                      => 'Título del sitio',
	setting_tos                        => 'Términos de servicio',
	setting_upload_dir                 => 'Ruta interna archivos cargados',
	setting_upload_web                 => 'Ruta web archivos cargados',

	validation_failed_username_username        => 'El nombre de usuario debe tener 4 o más caracteres alfanuméricos sin espacios',
	validation_failed_minlength_email          => 'El email debe tener 10 o más caracteres',
	validation_failed_email_email              => 'Dirección de email inválida',
	validation_failed_required_name            => 'El nombre es requerido',
	validation_failed_minlength_name           => 'El nombre debe tener 3 o más caracteres',
	validation_failed_maxlength_name           => 'El nombre no debe tener más de 64 caracteres',
	validation_failed_maxlength_gravatar_email => 'El email Gravatar no puede tener más de 250 caracteres',
	validation_failed_maxlength_about          => 'La breve bio no puede tener más de 1000 caracteres',

);

sub lp {

	my ( $key, @arg ) = @_;

	return exists( $strings{$key} ) ? &l( $key, @arg ) : $key;

}

sub l {

	my ( $key, @arg ) = @_;

	my $l = $strings{$key} // qq{Undefined string: $key};

	foreach my $sub (@arg) {
		$l =~ s/(?<!%)%/$sub/;
	}

	return $l;

}

1;
