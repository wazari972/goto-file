# urxvt prepends "use strict; use utf8;\n", screwing with our line numbers
#line 3

# =head1 NAME

# cwd-spawn - open a new urxvt within the current working directory.


# =head1 INSTALLATION

# /!\ you need to install cwd-spawn hooks for emacs goto to work:

# 1) adjust your F<.Xresources>
     
     # not necessary

# 2) copy/symlink this script into F</home/user/.urxvt>

     # not necessary

# 3) adjust your shell config to include these functions
#    (known to work with zsh/bash/ksh)

#     cwd_to_urxvt() {
#         local update="\0033]777;cwd-spawn;path;$PWD\0007"

#         case $TERM in
#         screen*)
#         # pass through to parent terminal emulator
#             update="\0033P$update\0033\\";;
#         esac

#         echo -ne "$update"
#     }

#     cwd_to_urxvt # execute upon startup to set initial directory

#     ssh_connection_to_urxvt() {
#         # don't propagate information to urxvt if ssh is used non-interactive
#         [ -t 0 ] || [ -t 1 ] || return

#         local update="\0033]777;cwd-spawn;ssh;$1\0007"

#         case $TERM in
#         screen*)
#         # pass through to parent terminal emulator
#             update="\0033P$update\0033\\";;
#         esac

#         echo -ne "$update"
#     }

# 4) adjust F<.ssh/config>

#     not necessary

# 5) execute cwd_to_urxvt each time you change your directory.

#     # zsh supports hooks which execute each time you change your cwd:
#     chpwd_functions=(${chpwd_functions} cwd_to_urxvt)

# Support for other shells are left as an exercise for the reader ;-)


# =head1 BUGS

# C<ssh> doesn’t invoke LocalCommand if you connect through “master” mode.
# Thus C<cwd-spawn> always copies the connection information into the new terminal.
# While this works fine for a single connection, it fails if you nest ssh connections (as a slave through “master” mode).
# As a workaround, manually invoke C<ssh_connection_to_urxvt "user host 22">.


# =head1 COPYRIGHT AND LICENSE

# Copyright (C) 2011 Maik Fischer L<maikf+urxvt@qu.cx>

# This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.


# =cut

use Cwd;
use Encode;
my $utf8 = Encode::find_encoding('UTF-8');

sub on_sel_grab  {
    my ($self, $term, $eventtime) = @_;

    $self->{'emacs-goto'} ||= {};

    $self->{'emacs-goto'}{'selection'} = $_[0]->selection;
}

sub on_osc_seq_perl {
    my ($self, $osc, $resp) = @_;

    return unless $osc =~ s/^cwd-spawn;//;

    # decode raw bytestring into utf8
    local $@;
    $osc = eval { $utf8->decode($osc, Encode::FB_CROAK) };
    if ($@) {
        warn "emacs-goto: called with garbage: $@";
        return;
    }

    return unless $osc =~ s/^(path);//;
    my $cmd = $1;

    my $storage = $self->{'emacs-goto'} ||= {};

    $storage->{path} = $osc;

    return 1;
}

sub on_user_command {
    my ($self, $cmd) = @_;

    my $target = $self->{'emacs-goto'}{'selection'}
        or return;

    my $cwd = $self->{'emacs-goto'}{'path'}
        or return;

    
    if (!($target =~ /^\/.*/)) {
	# absolute path
	$target = "$cwd/$target";
    }

    # save target filename
    my $filename = $target;
    # if has :, take it out
    my $colon = index($target, ":");
    if ($colon != -1) {
	$filename = substr($target, 0, $colon);
    }

    # test if target exists

    if (-e $filename) {
	warn "emacs-goto: goto $target";
    } else {
	warn "emacs-goto: $target doesn't exists.";
    }
    
    return;
}

# vim: set ts=4 sw=4 sts=4 ft=perl expandtab:
