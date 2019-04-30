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
			env     => $env,
			trail   => undef,
			session => $ses,
		},
		r       => $req,
		s       => $ses,
		session => $ses,
	};

	$self->{d}->{site} = $self->{m}->get_site();

	$env->{title} = $self->{d}->{site}->{title};

	$self->{m}->check_session($ses);

	$self->{m}->{l} = \&l;

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

	$s->{d}->{boards} = $s->{m}->get_boards( get_last_reply => 1 );

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

	$s->push_trail( { href => qq{/board/$board_id}, title => $s->{d}->{board}->{title} }, { href => qq{/thread/$board_id/$thread_id}, title => $s->{d}->{thread}->{subject} }, );

	return;

}

sub login {

	return;

}

sub do_login {

	my ($s) = @_;

	my $p = $s->{r}->parameters();

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
	}

	$s->{s}->{session_id} = $session_id;

	$s->{m}->check_session( $s->{s} );

	$s->{d}->{template} = 'index';
	$s->index();

	return;

}

sub new_thread {

	my ($s) = @_;

	my $p = $s->{r}->parameters();

	my $thread = {
		board_id => $p->{board_id},
		author   => $s->{s}->{user}->{user_id},
		subject  => $p->{subject},
		message  => undef,
	};

	utf8::decode( $thread->{subject} );

	$thread->{message} = $s->{m}->htmlize( $p->{message} );

	$s->{m}->insert( $thread, 'threads' );
	my $new_thread = $s->{m}->get_last_thread( board_id => $p->{board_id} );

	$s->{d}->{redirect} = qq{/thread/$p->{board_id}/$new_thread->{thread_id}};
	$s->{d}->{template} = 'thread';
	$s->thread( $p->{board_id}, $new_thread->{thread_id} );

	return;

}

sub new_reply {

	my ($s) = @_;

	my $p = $s->{r}->parameters();

	my $reply = {
		thread_id => $p->{thread_id},
		author    => $s->{s}->{user}->{user_id},
		message   => undef,
	};

	my $msg = $p->{message};
	$reply->{message} = $s->{m}->htmlize( $p->{message} );

	#die Dumper [ $reply, $msg ] ;

	$s->{m}->insert( $reply, 'replies' );

	$s->{d}->{redirect} = qq{/thread/$p->{board_id}/$p->{thread_id}};
	$s->{d}->{template} = 'thread';
	$s->thread( $p->{board_id}, $p->{thread_id} );

	return;

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

sub register {}

sub do_register {

	my ( $s, $user_id ) = @_;

	my $p = $s->{r}->parameters();
	
	$p->{email} =~ s/\s+$//;

	my $error;
	if    ( $p->{email}    !~ m/^[\S_.-]+\@[\S.-]+$/ )   { $error = 'invalid_email_address'; }
	elsif ( $p->{username} !~ m/^[a-z][a-z0-9]{3,32}$/ ) { $error = 'invalid_username'; }
	elsif ( $s->{m}->check_email_exists( $p->{email} ) )       { $error = 'email_address_already_registered'; }
	elsif ( $s->{m}->check_username_exists( $p->{username} ) ) { $error = 'username_already_registered'; }

	if ($error) {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l($error) };
		$s->{d}->{template} = 'register';
		$s->register();
		return;
	}
	else {
		$s->{m}->preregister( user_id => $p->{username}, email => $p->{email} );
		
		push @{ $s->{d}->{messages} }, { type => 'success', message => $s->l('confirmation_email_sent') };

		$s->{d}->{template} = 'index';
		$s->index();
	}

	return;

}

sub register_finish {

	my ( $s, $user_id ) = @_;

	my $p = $s->{r}->parameters();

	if ( $s->{m}->check_new_hash( $p->{hash} ) ) {
		$s->{d}->{valid_hash} = 1;
		$s->{d}->{template} = 'chpw';
		$s->chpw();
	}
	else {
		push @{ $s->{d}->{messages} }, { type => 'error', message => $s->l('invalid_preregister_hash') };
		$s->{d}->{template} = 'index';
		$s->index();
	}

}

sub chpw {}

sub logout {

	my ( $s, $data ) = @_;

	$s->{m}->delete_session( $s->{s} );

	$s->{d}->{template} = 'index';
	$s->index();

}

sub dump_settings {

	my ( $s, $data ) = @_;

	return $s->dumper({ s => $s, data => $data });
	
}

sub dumper {

	my ( $s, $data ) = @_;

	$s->{d}->{data} = $data;

	$s->{out}->template( filename => 'dumper', title => 'Dumper', data => $s->{d} );

}

1;
