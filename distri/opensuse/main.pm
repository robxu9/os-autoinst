#!/usr/bin/perl -w
use strict;
use bmwqemu;
use autotest;

sub installrunfunc
{
	my($test)=@_;
	my $class=ref $test;
	$test->run();
	$test->take_screenshot;
}

waitinststage "bootloader",12; # wait for welcome animation to finish

if($ENV{LIVETEST} && ($ENV{LIVECD} || $ENV{PROMO})) {
	$username="linux"; # LiveCD account
	$password="";
}
if($ENV{DESKTOP} eq "minimalx") {$ENV{XDMUSED}=1}
$ENV{TOGGLEHOME}=1;
autotest::runtestdir("$ENV{CASEDIR}/inst.d", undef);
autotest::runtestdir("$ENV{CASEDIR}/inst.d", \&installrunfunc);

if(my $d=$ENV{DESKTOP}) {
	do "inst/\L$d.pm" or diag $@;
}

1;
