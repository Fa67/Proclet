use strict;
use Test::More;
use File::Temp qw/tempdir tempfile/;
use List::MoreUtils qw/uniq/;

my ($tmpfh, $logfile) = tempfile(UNLINK=>0,EXLOCK=>0);
my $pid = fork();
$ENV{PROCLET_TESTFILE} = $logfile;

die $! if ! defined $pid;

if ( $pid == 0 ) {
    chdir 't/30proclet/procfile';
    close(STDERR);
    exec $^X, '-I../../../lib','../../../bin/proclet', 'start','-p','3000','w2';
    exit;
}

for (1..10) {
    open( my $fh, $logfile);
    my @lines = <$fh>;
    last if @lines > 2;
    sleep 1;
}

open(my $fh, $logfile);
my %logok;
my %port;
while( <$fh> ) {
    chomp;
    my @l = split / /;
    $logok{$l[0]} ||= {};
    $logok{$l[0]}->{$l[1]} = 1;
    $port{$l[0]} ||= [];
    push @{$port{$l[0]}}, $l[2]; 
}
close $fh;
ok(!exists $logok{w1});
is( scalar keys %{$logok{w2}},2);
is_deeply( [ uniq sort @{$port{w2}} ], [3100,3101] );
ok(!exists $logok{w3});

kill 'TERM', $pid;
waitpid( $pid, 0);
unlink($logfile);
done_testing();
