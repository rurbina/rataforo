package model;

use util;
use DBD::SQLite;
use DBI;
use Data::Dumper qw(Dumper);
$Data::Dumper::Sortkeys = 1;

sub new {

	my $s = { dbh => undef, };

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

sub insert {

	my ( $s, $data, $table ) = @_;

	my $p_data = $s->parametrize( $data, glue => ', ' );

	my $sql    = qq{INSERT INTO $table ($p_data->{sql}) VALUES ()};
	my @params = ( @{ $p_data->{params} } );
	die Dumper($sql);

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);
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

sub parametrize {

	my ( $s, $hash, %arg ) = @_;

	my ( @params, @sql );

	foreach my $key ( sort keys %{$hash} ) {
		if ( $key =~ m/(date|time)/ && $hash->{$key} eq 'now' ) {
			push @sql, qq{$key = datetime('now')};
		}
		else {
			push @sql,    qq{$key = ?};
			push @params, $hash->{$key};
		}
	}
	my $glue = $arg{glue} // ' and ';

	return { params => \@params, sql => join( $glue, @sql ) };

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

	my $sql = qq{
	select thread_id,board_id,author,subject,message,timestamp
	    from threads
	    where 1=1
	    $sql_board_id
	    $sql_thread_id
	    order by timestamp asc, thread_id asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@param);

	while ( my $thread = $sth->fetchrow_hashref() ) {
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

	my $thread = $s->get_threads( thread_id => $arg{thread_id} )->[0];

	$thread->{board} = $s->get_board( board_id => $thread->{board_id} );

	if ( $arg{get_replies} ) {
		$thread->{replies} = $s->get_replies( thread_id => $thread->{thread_id} );
	}

	return $thread;

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

	my $sql = qq{
	select thread_id,reply_id,author as author_id,message,timestamp
	    from replies
	    where 1=1
	    $sql_thread_id
	    order by timestamp asc, thread_id asc
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
	select user_id, name, about, timestamp, passwd, salt
	    from users
	    where 1=1
	    $sql_user_id
	    order by name asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);

	while ( my $row = $sth->fetchrow_hashref() ) {
		push @{$users}, $row;
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

	my $user = $s->get_user( user_id => $arg{user_id} );

	return 'user_not_found' unless $user;

	my $test = util->test_password( $arg{passwd}, $user->{passwd} );

	return 'bad_password' unless $test;

	$s->update( { user_id => $arg{user_id} }, { last_login_time => 'now' }, 'users' );

	return 'ok';

}

sub check_session {

	my ( $s, $ses ) = @_;

	return unless $$ses;

	my $sql = qq{SELECT user_id FROM sessions WHERE session_id = ?};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute($ses);

	my ($user_id) = $sth->fetchrow_array();

	$sth->finish();

	if ($user_id) {
		$ses = $s->get_user($user_id);
		$ses->{session_id} = $ses;
		return 1;
	}

	return;

}

1;
