package controller;

use common::sense;
use output;
use model;
use util;
use Encode qw(decode);
use Try::Tiny;
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

sub new {

	my ( $class, $env, $req, $ses ) = @_;

	my $self = {
		out => output->new(),
		m   => model->new(),
		d   => {
			env      => $env,
			trail    => undef,
			session  => $ses,
			messages => [],
		},
		r       => $req,
		s       => $ses,
		session => $ses,
		params  => {},
	};

	$self->{d}->{site} = $self->{m}->get_site();

	$env->{title} = $self->{d}->{site}->{title};

	$self->{m}->check_session($ses);

	$self->{m}->{l} = \&l;

	my @param_keys = $req->multi_param();
	foreach my $key (@param_keys) {
		my $dkey = "$key";
		my $dval = "" . $req->param($key);
		utf8::decode($dkey);
		utf8::decode($dval);
		$self->{params}->{$dkey} = $dval;
	}

	$self->{d}->{params} = $self->{params};

	bless $self;

}

sub l {

	my ( $s, $key ) = @_;
	use lang_es_mx;

	&lang_es_mx::l($key);

}

sub lp {

	my ( $s, @params ) = @_;
	use lang_es_mx;

	&lang_es_mx::lp(@params);

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

	$s->{d}->{boards} = $s->{m}->get_boards( get_last_reply => 1, get_stats => 1 );

	$s->set_title( $s->l('board_index') );

	if ( $s->{params}->{logout} ) {
		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('logged_out') };
	}

	return;

}

sub board {

	my ( $s, $board_id ) = @_;

	$s->{d}->{board} = $s->{m}->get_board(
		board_id        => $board_id,
		user_id         => $s->{session}->{user}->{user_id},
		get_threads     => 1,
		threads_page    => int( $s->{params}->{page} ),
		get_last_reply  => 1,
		get_new_replies => 1,
		get_stats       => 1,
	) or die 'board not found';

	$s->set_title( $s->{d}->{board}->{title} );
	$s->push_trail( { href => qq{/board/$board_id}, title => $s->{d}->{board}->{title} } );

	return;

}

sub thread {

	my ( $s, $board_id, $thread_id ) = @_;

	$s->{d}->{thread} = $s->{m}->get_thread( thread_id => $thread_id, get_replies => 1 )
	  or die 'thread not found';

	$s->{d}->{board} = $s->{m}->get_board( board_id => $s->{d}->{thread}->{board_id} );

	if ( $s->{session}->{user} ) {
		$s->{m}->touch_thread( user_id => $s->{session}->{user}->{user_id}, thread_id => $thread_id );
	}

	$s->push_trail( { href => qq{/board/$board_id}, title => $s->{d}->{board}->{title} }, { href => qq{/thread/$board_id/$thread_id}, title => $s->{d}->{thread}->{subject} }, );

	return;

}

sub login {

	return;

}

sub do_login {

	my ($s) = @_;

	my $p = $s->{params};

	my $session_id;

	my $direct_session;

	if ( $p->{session} ) {
		$direct_session = { session_id => $p->{session} };
	}

	my $status = $s->{m}->login(
		user_id        => $p->{user_id},
		passwd         => $p->{passwd},
		direct_session => $direct_session,
		session_id     => \$session_id,
	);

	if ( $status eq 'ok' ) {
		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('login_success') };
	}
	else {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l( $status // 'login_error' ) };
		$s->{d}->{template} = 'index';
		return $s->index();
	}

	$s->{s}->{session_id} = $session_id;
	$s->{m}->check_session( $s->{s} );

	return { redirect => '/index' };

}

sub new_thread {

	my ($s) = @_;
	$s->assert_session();

	my $p = $s->{params};

	my $thread = {
		board_id => $p->{board_id},
		author   => $s->{s}->{user}->{user_id},
		subject  => $p->{subject},
		message  => undef,
	};

	$thread->{message} = util->htmlize( $p->{message} );

	die 'message_must_not_be_empty' unless $p->{message};
	die 'message_must_not_be_empty' unless $thread->{message};

	$s->{m}->insert( $thread, 'threads' );

	my $new_thread = $s->{m}->get_last_thread( board_id => $p->{board_id} );

	return { redirect => qq{/thread/$p->{board_id}/$new_thread->{thread_id}} };

}

sub new_reply {

	my ($s) = @_;
	$s->assert_session();

	my $p = $s->{params};

	my $reply = {
		thread_id => $p->{thread_id},
		author    => $s->{s}->{user}->{user_id},
		message   => undef,
	};

	$reply->{message} = util->htmlize( $p->{message} );

	die 'message_must_not_be_empty' unless $p->{message};
	die 'message_must_not_be_empty' unless $reply->{message};

	$s->{m}->insert( $reply, 'replies' );

	return { redirect => qq{/thread/$p->{board_id}/$p->{thread_id}} };

}

sub users {

	my ( $s, $user_id ) = @_;

	$s->{d}->{users} = $s->{m}->get_users();

	$s->push_trail( { href => qq{/users}, title => $s->l('users') } );

	return;

}

sub user {

	my ( $s, $user_id ) = @_;

	$s->{d}->{user} = $s->{m}->get_user( user_id => $user_id );

	$s->push_trail( { href => qq{/users}, title => $s->l('users') }, { href => qq{/user/$user_id}, title => $s->{d}->{user}->{name} }, );

	return;

}

sub modify_user {

	my ( $s, $user_id ) = @_;

	die 'cannot_modify_other_users_info' unless $user_id eq $s->{session}->{user}->{user_id};

	$s->{d}->{user} = $s->{m}->get_user( user_id => $user_id );

	$s->push_trail(
		{ href => qq{/users}, title => $s->l('users') },
		{ href => qq{/user/$user_id}, title => $s->{d}->{user}->{name} },
		{ href => qq{/modify_user/$user_id}, title => $s->l('modify_user') },
	);

	return;

}

sub do_modify_user {

	my ( $s, $user_id ) = @_;

	my %input = eval {
		util->validate_input(
			input => $s->{params},
			check => [
				[ name           => [ 'required', [ 'minlength', 3 ], [ 'maxlength', 64 ] ] ],
				[ gravatar_email => [ [ 'maxlength', 255 ] ] ],
				[ about          => [ [ 'maxlength', 1023 ] ] ],
			],
		);
	};
	my $error = $@;

	if ( $user_id ne $s->{session}->{user}->{user_id} ) {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l('cannot_modify_other_users_info') };
	}
	elsif ($error) {
		my @error = split( ' ', $error, 2 );
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l( $error[0] ) };
	}
	else {
		$s->{m}->set_user( user_id => $user_id, %input );

		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('modify_user_success') };

		return { redirect => qq{/user/$user_id} };
	}

	$s->{d}->{template} = 'modify_user';
	return $s->modify_user($user_id);

}

sub register {

	my ($s) = @_;

	if ( $s->{d}->{site}->{tos} ) {
		$s->{d}->{tos} = util->htmlize_file( $s->{d}->{site}->{tos} );
	}

	return;

}

sub do_register {

	my ( $s, $user_id ) = @_;

	my @checks = (
		[ email    => [ 'email',    [ 'minlength', 10 ], [ 'maxlength', 64 ] ] ],
		[ username => [ 'username', [ 'minlength', 3 ],  [ 'maxlength', 32 ] ] ],
	);

	push( @checks, [ passwd => [ [ 'minlength', 4 ] ] ] ) unless $s->{d}->{site}->{require_email_confirmation};

	try {
		# standard validations
		my %input = util->validate_input( input => $s->{params}, check => \@checks );

		# special ones
		my $p = $s->{params};

		$p->{email} =~ s/\s+$//;

		if    ( $p->{email} !~ m/^[\S_.-]+\@[\S.-]+$/ )            { die [ invalid_email_address => $p->{email} ]; }
		elsif ( $p->{username} !~ m/^[a-z][a-z0-9]{3,32}$/ )       { die [ invalid_username => $p->{username} ]; }
		elsif ( $s->{m}->check_email_exists( $p->{email} ) )       { die [ email_address_already_registered => $p->{email} ]; }
		elsif ( $s->{m}->check_username_exists( $p->{username} ) ) { die 'username_already_registered'; }

		# confirmation via email, messy
		if ( $s->{d}->{site}->{require_email_confirmation} ) {

			$s->{m}->preregister( user_id => $p->{username}, email => $p->{email} );

			push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('confirmation_email_sent') };

			$s->{d}->{template} = 'index';
			return $s->index();
			return { redirect => qq{/index} };

		}

		# direct registration, less hassle but more spam
		else {
			$s->{m}->add_user( username => $p->{username}, email => $p->{email}, password => $p->{passwd} );

			my $session_id;
			my $status = $s->{m}->login( user_id => $p->{username}, passwd => $p->{passwd}, session_id => \$session_id );
			if ( $status ne 'ok' ) {
				die 'register_failed';
			}

			$s->{s}->{session_id} = $session_id;
			$s->{m}->check_session( $s->{s} );

			push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('register_complete') };
			$s->{d}->{template} = 'index';
			return $s->index();
		}
	}
	catch {
		my $message = util->process_error($_);
		push @{ $s->{d}->{messages} }, { type => 'error', message => $message };
		$s->{d}->{template} = 'register';
		return $s->register();
	};

}

sub register_finish {

	my ( $s, $user_id ) = @_;

	my $p = $s->{params};

	my $session_id = $s->{m}->check_new_hash( $p->{hash} );

	if ($session_id) {

		$s->{s}->{session_id} = $session_id;
		$s->{m}->check_session( $s->{s} );

		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('set_your_password_to_finish') };
		$s->{d}->{valid_hash} = $p->{hash};

		$s->{d}->{template} = 'chpw';
		return $s->chpw();
	}
	else {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l('invalid_preregister_hash') };
		$s->{d}->{template} = 'index';
		return $s->{index};
	}

}

sub chpw {

	my ($s) = @_;

	$s->assert_session();

	if ( !$s->{session}->{user} ) {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l('error_not_logged_in') };
		$s->{d}->{template} = 'index';
		return $s->{index};
	}

	if ( $s->{session}->{user}->{passwd} =~ m/^[0-9a-f]{32}$/ ) {
		$s->{d}->{valid_hash} = $s->{session}->{user}->{passwd};
	}

	return;

}

sub do_chpw {

	my ($s) = @_;

	$s->assert_session();

	my $old_ok;
	my $new_ok;

	$old_ok = 1 if $s->{session}->{user}->{passwd} eq $s->{params}->{hash};
	$old_ok = 1 if util->test_password( $s->{params}->{oldpw}, $s->{session}->{user}->{passwd} );

	$new_ok = 1 if length( $s->{params}->{newpw} ) >= 4 && $s->{params}->{newpw} eq $s->{params}->{chkpw};

	if ( $old_ok && $new_ok && $s->{m}->set_password( user_id => $s->{session}->{user}->{user_id}, password => $s->{params}->{newpw} ) ) {
		$s->success('password_updated');
		$s->{d}->{template} = 'user';
		return $s->user( $s->{session}->{user}->{user_id} );
	}
	elsif ( !$old_ok ) {
		$s->error('error_passwords_do_not_match');
	}
	elsif ( !$new_ok ) {
		$s->error('error_new_password_is_invalid');
	}

	$s->{d}->{template} = 'chpw';
	return $s->chpw();
}

sub logout {

	my ( $s, $data ) = @_;

	$s->{m}->delete_session( $s->{s} );

	return { redirect => '/index?logout=1' };

}

sub dump_settings {

	my ( $s, $data ) = @_;

	return $s->dumper( { s => $s, data => $data } );

}

sub dumper {

	my ( $s, $data ) = @_;

	$s->{d}->{data} = $data;

	$s->{out}->template( filename => 'dumper', title => 'Dumper', data => $s->{d} );

}

sub ipcheck {

	my ( $s, $data ) = @_;

	my $text = $s->{d}->{env}->{HTTP_X_REAL_IP} // $s->{d}->{env}->{REMOTE_ADDR};

	$s->{out}->text($text);

}

sub assert_session {

	my ($s) = @_;
	return util->assert_session( $s->{session} );

}

sub error {
	my ( $s, $msg ) = @_;
	push @{ $s->{d}->{messages} }, { type => 'error', message => $s->lp($msg) };
}

sub success {
	my ( $s, $msg ) = @_;
	push @{ $s->{d}->{messages} }, { type => 'success', message => $s->lp($msg) };
}

sub session_required {

	my ($s) = @_;
	$s->error('error_not_logged_in');
	$s->{d}->{template} = 'login';
	return $s->login();

}

1;
