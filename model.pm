package model;

use utf8;
use util;
use DBD::SQLite;
use DBI;
use Data::GUID;
use Encode;
use File::Temp qw(tempfile);
use File::Slurper qw(write_text read_text);
use Digest::MD5 qw(md5_hex);
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

sub new {

	my $s = {
		dbh => undef,
		l   => undef,
	};

	$s->{dbh} = DBI->connect(
		"dbi:SQLite:dbname=rataforo.db",
		"", "",
		{
			RaiseError     => 1,
			PrintError     => 0,
			sqlite_unicode => 1,
		}
	) or die $DBI::errstr;

	bless $s;

}

sub l {

	my $s = shift;

	&{ $s->{l} }(@_);

}

sub insert {

	my ( $s, $data, $table ) = @_;

	my $p_data = $s->parametrize($data);
	my $names  = join( ',', @{ $p_data->{names} } );
	my $qmarks = join( ',', ('?') x scalar( @{ $p_data->{names} } ) );
	my $sql    = qq{INSERT INTO $table ($names) VALUES ($qmarks)};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute( @{ $p_data->{params} } );
	$sth->finish();

}

sub update {

	my ( $s, $index, $data, $table ) = @_;

	my $p_data  = $s->parametrize( $data, glue => ', ' );
	my $p_index = $s->parametrize($index);

	my $sql    = qq{UPDATE $table SET $p_data->{sql} WHERE $p_index->{sql}};
	my @params = ( @{ $p_data->{params} }, @{ $p_index->{params} } );

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);
	$sth->finish();

}

sub delete {

	my ( $s, $index, $table ) = @_;

	my $p_index = $s->parametrize($index);

	my $sql    = qq{DELETE FROM $table WHERE $p_index->{sql}};
	my @params = @{ $p_index->{params} };

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);
	$sth->finish();

}

sub parametrize {

	my ( $s, $hash, %arg ) = @_;

	my ( @params, @sql, @names );

	foreach my $key ( sort keys %{$hash} ) {
		if ( $key =~ m/(date|time)/ && $hash->{$key} eq 'now' ) {
			push @sql, qq{$key = datetime('now')};
		}
		else {
			push @sql,    qq{$key = ?};
			push @params, $hash->{$key};
			push @names,  $key;
		}
	}
	my $glue = $arg{glue} // ' and ';

	return { params => \@params, sql => join( $glue, @sql ), names => \@names };

}

sub get_site {

	my ($s) = @_;

	my $site = {};

	my $sql = qq{
	select key,value from settings
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute();

	while ( my ( $key, $value ) = $sth->fetchrow_array() ) {
		$site->{$key} = $value;
	}

	$sth->finish();

	$s->{site} = $site;

	return $site;

}

sub get_boards {

	my ( $s, %arg ) = @_;

	my $boards = [];

	my @params;
	my $sql_board_id;

	if ( $arg{board_id} ) {
		push @params, $arg{board_id};
		$sql_board_id = qq{and board_id = ?};
	}

	my $sql = qq{
	select board_id, title, description
	    from boards
	    where 1=1
	    $sql_board_id
	    order by sort asc, title asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);

	while ( my $row = $sth->fetchrow_hashref() ) {

		if ( $arg{get_last_reply} ) {
			$row->{last_thread} = $s->get_last_thread( board_id => $row->{board_id} );
			$row->{last_reply} = $s->get_last_reply( thread_id => $row->{last_thread}->{thread_id} );
		}

		push @{$boards}, $row;
	}

	$sth->finish();

	return $boards;

}

sub get_threads {

	my ( $s, %arg ) = @_;

	my @param;
	my $threads = [];
	my ( $sql_board_id, $sql_thread_id );

	if ( $arg{board_id} ) {
		$sql_board_id = qq{and threads.board_id = ?};
		push @param, $arg{board_id};
	}

	if ( $arg{thread_id} ) {
		$sql_thread_id = qq{and threads.thread_id = ?};
		push @param, $arg{thread_id};
	}

	my $order_by = $arg{order_by} ? qq{order by $arg{order_by}} : qq{order by timestamp desc, thread_id asc};

	my $limit = qq{limit $arg{limit}} if $arg{limit} > 0;

	my $sql = qq{
	select thread_id, board_id, author as author_id, subject, message, timestamp
	    from threads
	    where 1=1
	    $sql_board_id
	    $sql_thread_id
	    $order_by
	    $limit
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@param);

	while ( my $thread = $sth->fetchrow_hashref() ) {

		$thread->{author} = $s->get_user( user_id => $thread->{author_id} );

		push @{$threads}, $thread;
	}

	$sth->finish();

	return $threads;

}

sub get_board {

	my ( $s, %arg ) = @_;

	my $board = $s->get_boards( board_id => $arg{board_id} )->[0];

	if ( $arg{get_threads} ) {
		$board->{threads} = $s->get_threads( board_id => $board->{board_id} );
	}

	return $board;

}

sub get_thread {

	my ( $s, %arg ) = @_;

	my %params;
	$params{thread_id} = $arg{thread_id} if $arg{thread_id};
	$params{limit}     = $arg{limit}     if $arg{limit};

	my $thread = $s->get_threads(%params)->[0];

	$thread->{board} = $s->get_board( board_id => $thread->{board_id} );

	if ( $arg{get_replies} ) {
		$thread->{replies} = $s->get_replies( thread_id => $thread->{thread_id} );
	}

	return $thread;

}

sub get_last_thread {

	my ( $s, %arg ) = @_;

	return $s->get_threads( board_id => $arg{board_id}, order_by => 'timestamp desc', limit => 1 )->[0];

}

sub get_last_reply {

	my ( $s, %arg ) = @_;

	return $s->get_replies( thread_id => $arg{thread_id}, order_by => 'timestamp desc', limit => 1 )->[0];

}

sub get_replies {

	my ( $s, %arg ) = @_;

	my @param;
	my $replies = [];
	my ($sql_thread_id);

	if ( $arg{thread_id} ) {
		$sql_thread_id = qq{and replies.thread_id = ?};
		push @param, $arg{thread_id};
	}

	my $order_by = $arg{order_by} ? qq{order by $arg{order_by}} : qq{order by timestamp asc, thread_id asc};
	my $limit = qq{limit $arg{limit}} if $arg{limit} > 0;

	my $sql = qq{
	select thread_id,reply_id,author as author_id,message,timestamp
	    from replies
	    where 1=1
	    $sql_thread_id
	    $order_by
	    $limit
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@param);

	while ( my $reply = $sth->fetchrow_hashref() ) {

		$reply->{author} = $s->get_user( user_id => $reply->{author_id} );

		push @{$replies}, $reply;
	}

	$sth->finish();

	return $replies;

}

sub get_users {

	my ( $s, %arg ) = @_;

	my $users = [];

	my @params;
	my $sql_user_id;

	if ( $arg{user_id} ) {
		push @params, $arg{user_id};
		$sql_user_id = qq{and user_id = ?};
	}

	my $sql = qq{
	select user_id, name, email, about, timestamp, passwd, disabled, confirmed,
	    coalesce(nullif(gravatar_email,''),user_id) as gravatar_email
	    from users
	    where 1=1
	    $sql_user_id
	    order by name asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);

	while ( my $user = $sth->fetchrow_hashref() ) {

		$user->{gravatar_hash} = md5_hex( $user->{gravatar_email} );
		$user->{gravatar}      = "https://www.gravatar.com/avatar/$user->{gravatar_hash}";

		push @{$users}, $user;
	}

	$sth->finish();

	return $users;

}

sub get_user {

	my ( $s, %arg ) = @_;

	my $user = $s->get_users( user_id => $arg{user_id} )->[0];

	return $user;

}

sub login {

	my ( $s, %arg ) = @_;

	if ( ref( $arg{direct_session} ) eq 'HASH' && $s->check_session( $arg{direct_session} ) ) {
		return 'ok';
	}

	my $user = $s->get_user( user_id => $arg{user_id} );

	return 'user_not_found' unless $user;

	my $test = util->test_password( $arg{passwd}, $user->{passwd} );

	return 'bad_password' unless $test or ( $arg{plain} && $arg{passwd} eq $user->{passwd} );

	$s->update( { user_id => $arg{user_id} }, { last_login_time => 'now' }, 'users' );

	my $session_id = Data::GUID->new()->as_string();

	$s->insert( { session_id => $session_id, user_id => $user->{user_id} }, 'sessions' );

	${ $arg{session_id} } = $session_id;

	return 'ok';

}

sub set_password {

	my ( $s, %arg ) = @_;

	my $hashed = util->encrypt_password( $arg{password} );

	$s->update( { user_id => $arg{user_id} }, { passwd => $hashed }, 'users' );

	return 1;

}

sub check_session {

	my ( $s, $ses ) = @_;

	# delete old registration requests -- do we need to?
	$s->{dbh}->do(
		qq{
		      DELETE FROM new_users
		      WHERE ((strftime('%s', timestamp) - strftime('%s', 'now')) / 86400) > 7}
	);

	# delete old sessions
	$s->{dbh}->do(
		qq{
		      DELETE FROM sessions
		      WHERE ((strftime('%s', last_touch_time) - strftime('%s', 'now')) / 86400) > 35}
	);

	return unless ref($ses) eq 'HASH' && $ses->{session_id};

	my $sql = qq{SELECT user_id FROM sessions WHERE session_id = ?};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute( $ses->{session_id} );

	my ($user_id) = $sth->fetchrow_array();

	$sth->finish();

	if ($user_id) {
		$ses->{user}      = $s->get_user( user_id => $user_id );
		$ses->{can_post}  = 1;
		$ses->{can_reply} = 1;
		return 1;
	}
	else {
		delete $ses->{session_id};
	}

	return;

}

sub delete_session {

	my ( $s, $ses ) = @_;

	my $sql = qq{DELETE FROM sessions WHERE session_id = ?};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute( $ses->{session_id} );

	my ($user_id) = $sth->fetchrow_array();

	$sth->finish();

	$ses = {};

	return;

}

sub touch_session {

	my ( $s, $ses ) = @_;

	return unless ref($ses) eq 'HASH' && $ses->{session_id};

	$s->update( { last_touch_time => 'now' }, { session_id => $ses->{session_id} }, 'sessions' );

}

sub check_email_exists {

	my ( $s, $email ) = @_;

	my $sql = qq{SELECT 1 FROM users WHERE email = ? LIMIT 1};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute($email);

	my ($exists) = $sth->fetchrow_array();

	$sth->finish();

	return 1 if $exists;

}

sub check_username_exists {

	my ( $s, $username ) = @_;

	my $sql = qq{SELECT 1 FROM users WHERE user_id = ? LIMIT 1};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute($username);

	my ($exists) = $sth->fetchrow_array();

	$sth->finish();

	return 1 if $exists;

}

sub preregister {

	my ( $s, %pp ) = @_;

	my $hash = md5_hex( localtime . $pp{user_id} . $pp{email} . \%pp );

	my $url = $s->{site}->{site_url} . '/register_finish?hash=' . $hash;

	do {
		use Email::Simple;
		use Email::Sender::Simple qw(sendmail);

		my $body = qq{<!DOCTYPE html><html><body>\n} .
		    util->htmlize_file( $s->{site}->{register_instructions} ) .
		    qq{\n</body></html>\n};

		$body =~ s/\$url/<a href="$url">$url<\/a>/;

		$body =~ m/<h1>(.*?)<\/h1>/;
		$subject = $1 // 'Registro en foro';

		my $email = Email::Simple->create(
			header => [
				From           => qq{$s->{site}->{title} <$s->{site}->{email_from}>},
				To             => qq{$pp{user_id} <$pp{email}>},
				Subject        => qq{$s->{site}->{title}: $subject},
				'Content-Type' => 'text/html; charset="ISO-8859-1"',
			],
			body => $body,
		);

		sendmail($email);

	};

	$s->insert(
		{
			user_id   => $pp{user_id},
			email     => $pp{email},
			hash      => $hash,
			timestamp => 'now',
		},
		'new_users',
	);

}

sub check_new_hash {

	my ( $s, $hash ) = @_;

	my $sql = qq{select user_id,email from new_users where hash = ?};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute($hash);

	my ( $user_id, $email ) = $sth->fetchrow_array();

	$sth->finish();

	if ($user_id) {
		$s->insert(
			{
				user_id   => $user_id,
				name      => $user_id,
				email     => $email,
				passwd    => $hash,
				disabled  => 0,
				confirmed => 1,
			},
			'users'
		);

		$s->delete( { user_id => $user_id }, 'new_users' );

		my $session_id;
		$s->login( user_id => $user_id, passwd => $hash, plain => 1, session_id => \$session_id );
		
		return $session_id;
	}

	return;

}

1;
