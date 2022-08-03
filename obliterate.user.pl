#! /usr/bin/perl

use common::sense;
use lib '.';
use model;
use Getopt::Std;

our( $opt_u, $opt_l, $opt_d, $opt_k );

getopts('d:lu:k');


if ( !$opt_d ) {
	die "usage: $ARGV[0] -d <database> (-l | -u user_id)\n"
}

my $m = model::new( db => $opt_d );



if ( $opt_u ) {

	# look for user
	my $user = $m->get_user( user_id => $opt_u );

	print "$user->{user_id}\t$user->{name}\t$user->{email}\n";

	$m->update( { user_id => $user->{user_id} }, { disabled => 1, passwd => '**disabled**' }, 'users' );
	print "$user->{user_id} disabled\n";

	if ( $opt_k ) {

		# delete all replies from this user
		print "deleting replies from this user... ";
		$m->delete( { author => $user->{user_id} }, 'replies' );
		print "done\n";

		# find all user's threads
		print "deleting threads from this user... ";
		my $threads = $m->get_threads( author => $user->{user_id} );
		foreach my $thread ( @$threads ) {
			print "\t$thread->{subject}\n";
		}
		print "done\n";
	}
	
}
else {

	my $users = $m->get_users();

	foreach my $user ( @$users ) {
		print "$user->{user_id}\t$user->{name}\t$user->{email}\t$user->{disabled}\n";
	}
	
}
