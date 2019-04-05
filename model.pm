package model;

use utf8;
use DBD::Sqlite;
use DBI;

sub new {

	my $s = { dbh => undef, };

	$s->{dbh} = DBI->connect(
		"dbi:SQLite:dbname=rataforo.db", "", "",
		{
			RaiseError => 1,
			PrintError => 0,
			sqlite_unicode => 1,
		}
	) or die $DBI::errstr;

	bless $s;

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

	my ($s, %arg) = @_;

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
	    where true
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
	    where true
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
	select thread_id,reply_id,author,message,timestamp
	    from replies
	    where true
	    $sql_thread_id
	    order by timestamp asc, thread_id asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@param);

	while ( my $reply = $sth->fetchrow_hashref() ) {
		push @{$replies}, $reply;
	}

	$sth->finish();

	return $replies;

}

1;
