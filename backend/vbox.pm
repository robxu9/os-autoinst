#!/usr/bin/perl -w

package backend::vbox;
use strict;
use Cwd 'abs_path';

#use FindBin;
#use lib "$FindBin::Bin/backend";
#use lib "$FindBin::Bin/backend/helper";
#use lib "$FindBin::Bin/helper";
use base ('backend::helper::scancodes', 'backend::baseclass');

our $scriptdir = $bmwqemu::scriptdir || '.';

sub init() {
	my $self = shift;
	$self->{'vmname'} = 'osautoinst';
	$self->{'pid'} = undef;
	$self->backend::helper::scancodes::init();
}


# scancode virt method overwrite

sub keycode_down($) {
        my $self = shift;
	my $key = shift;
	my $keycode = $self->{'keymaps'}->{'vbox'}->{$key};
	if($keycode>=0x80) {return (0xe0, $keycode ^ 0x80);}
	return ($keycode);
}

sub keycode_up($) {
        my $self = shift;
	my $key = shift;
	my $keycode = $self->{'keymaps'}->{'vbox'}->{$key};
	if($keycode>=0x80) {return (0xe0, $keycode);}
	return ($keycode ^ 0x80);
}

sub raw_keyboard_io($) {
        my $self = shift;
	my $data = shift;
	my @codes = map(sprintf("%02x", $_), @$data);
	$self->raw_vbox_controlvm("keyboardputscancode", @codes);
}

# scancode virt method overwrite end


# baseclass virt method overwrite

sub screendump($) {
	my $self = shift;
	my $filename = shift;
	my $r = int(rand(1e9));
	my $tmp = "/tmp/vbox-$r.png";
	$self->raw_vbox_controlvm("screenshotpng", $tmp);
	system("convert", $tmp, $filename);
	unlink $tmp;
}

sub power($) {
	# parameters:
	# acpi, reset, off
	my $self = shift;
	my $action = shift;
	if ($action eq 'acpi') {
		$self->raw_vbox_controlvm("acpipowerbutton");
	}
	elsif ($action eq 'reset') {
		$self->raw_vbox_controlvm("reset");
	}
	elsif ($action eq 'off') {
		$self->raw_vbox_controlvm("poweroff");
	}
}

#sub mouse_move($) { ( move / set)
#	# TODO ( move / set)
#	# not too bad because cursor does not appear on screenshot
#}

#sub mouse_button($) {
#	# TODO
#}

sub insert_cd($) {
	my $self = shift;
	my $iso = shift;
	system(qq'VBoxManage storageattach '.$self->{vmname}.' --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium '.$iso);
}

sub eject_cd($) {
	my $self = shift;
	system(qq'VBoxManage storageattach '.$self->{'vmname'}.' --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium emptydrive');
}

sub start_audiocapture($) {
	my $self = shift;
	my $wavfilename = shift;
	system("$scriptdir/tools/pawav.pl $wavfilename &");
}

sub stop_audiocapture($) {
	system("killall", "parec");
}

sub raw_alive($) {
	my $self = shift;
	return 0 unless $self->{'pid'};
	return kill(0, $self->{'pid'});
}

sub do_start_vm {
	my $self = shift;
	$self->raw_vbox_controlvm("poweroff"); # stop if running
	# TODO: assemble VM with ISO and disks similar to startqemu.pm
	# attach iso as DVD:
	$self->insert_cd($ENV{ISO});
	# pipe serial console output to file:
	system("VBoxManage", "modifyvm", $self->{vmname}, "--uartmode1", "file", abs_path("serial0"));
	system("VBoxManage", "modifyvm", $self->{vmname}, "--uart1", "0x3f8", 4);
	system("VBoxManage", "startvm", $self->{vmname});
	my $pid=`pidof VirtualBox`; chomp($pid);
	$pid=~s/ .*//; # use first pid, in case GUI was open
	$self->{'pid'} = $pid;
	#return 1;
	return(($?>>8)==0);
}

# baseclass virt method overwrite end


sub raw_vbox_controlvm($) {
	my $self = shift;
	system("VBoxManage", "controlvm", $self->{'vmname'}, @_);
}

1;
