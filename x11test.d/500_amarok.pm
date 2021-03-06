use base "basetest";
use bmwqemu;

sub is_applicable()
{
	return $ENV{DESKTOP} eq "kde";
}

sub run()
{
	my $self=shift;
	ensure_installed("amarok");
	x11_start_program("amarok /usr/share/sounds/alsa/test.wav");
	waitidle;
	$self->take_screenshot;
	sendkey "alt-f4"; sleep 3; # amazon store country popup
	$self->take_screenshot;
	sendkey "alt-d"; sendkeyw "alt-n"; # mp3 popup
#	sendkey "alt-f4"; sleep 3; # close kwallet popup
	$self->take_screenshot;
	sendkeyw "alt-y"; # use music path as collection folder
	$self->take_screenshot;
	sendkey "ctrl-q"; # really quit (alt-f4 just backgrounds)
	sleep 2; waitidle;
	x11_start_program("killall amarok") unless $ENV{NICEVIDEO}; # to be sure that it does not interfere with later tests
}

sub checklist()
{
	# return hashref:
	# bad: has random bits in pixels at (68,67-69)
	return {qw(
		efc74946144a6260943d4383a972dafb OK
		37834e420389f2a96e896d520010c629 OK
		0a2bf068e5fb68024db5aae0b704c340 OK
		906f3c3ef44f02df0c65b46bee949c2b OK
		2a489d82fb2cdab4fedfb187676d01c3 OK
		c7d193456b68158aef4975e5835ea675 OK
		0118160808373fa4eda70e0005a7d51e fail
	)}
}

1;
