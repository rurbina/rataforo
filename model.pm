package model;

use utf8;
use util;
use Switch qw(Perl6);
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
	select user_id, name, about, timestamp, passwd, disabled, confirmed
	    from users
	    where 1=1
	    $sql_user_id
	    order by name asc
	};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute(@params);

	while ( my $user = $sth->fetchrow_hashref() ) {

		$user->{email_hash} = md5_hex( $user->{email} );
		$user->{gravatar}   = "https://www.gravatar.com/avatar/$user->{email_hash}";

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

	my $user = $s->get_user( user_id => $arg{user_id} );

	return 'user_not_found' unless $user;

	my $test = util->test_password( $arg{passwd}, $user->{passwd} );

	return 'bad_password' unless $test;

	$s->update( { user_id => $arg{user_id} }, { last_login_time => 'now' }, 'users' );

	my $session_id = Data::GUID->new()->as_string();

	$s->insert( { session_id => $session_id, user_id => $user->{user_id} }, 'sessions' );

	${ $arg{session_id} } = $session_id;

	return 'ok';

}

sub check_session {

	my ( $s, $ses ) = @_;

	return unless ref($ses) eq 'HASH' && $ses->{session_id};

	my $sql = qq{SELECT user_id FROM sessions WHERE session_id = ?};

	my $sth = $s->{dbh}->prepare($sql);
	$sth->execute( $ses->{session_id} );

	my ($user_id) = $sth->fetchrow_array();

	$sth->finish();

	if ($user_id) {
		$ses->{user}      = $s->get_user($user_id);
		$ses->{can_post}  = 1;
		$ses->{can_reply} = 1;
		return 1;
	}
	else {
		delete $ses->{session_id};
	}

	return;

}

sub touch_session {

	my ( $s, $ses ) = @_;

	return unless ref($ses) eq 'HASH' && $ses->{session_id};

	$s->update( { last_touch_time => 'now' }, { session_id => $ses->{session_id} }, 'sessions' );

}

sub htmlize {

	my ( $s, $message, %arg ) = @_;

	my $html;
	$arg{lang} //= 'cmark';

	given $arg{lang}{
		when 'raw' {
			$html = $message;
		}
		when 'cmark' {
			my ( $tmp, $tmpfn ) = tempfile();
			write_text( $tmpfn, $message );
			system("cmark --to html --smart $tmpfn > $tmpfn.html");
			$html = read_text("$tmpfn.html");
			utf8::decode($html);
			unlink $tmpfn, "$tmpfn.html";
		}
	};

	return $html;

}

1;
