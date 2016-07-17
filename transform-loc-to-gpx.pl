#!/usr/bin/env perl
#
# Convert Geocaching .loc files into basic .gpx files
#
# Written by Andreas 'ads' Scherbaum <ads@wars-nicht.de>
#
# License: GNU GENERAL PUBLIC LICENSE, Version 3
#
# Version:
#   1.0   2016-07-16
#         initial version
#

use strict;
use warnings;
use FileHandle;


# all arguments are filenames
if (scalar(@ARGV) == 0) {
    help();
    exit(0);
}





# first scan all arguments if each of them is a file
my $error = 0;
foreach my $file (@ARGV) {
    if (!-f $file) {
        print STDERR "Argument $file is not a file\n";
        $error++;
    } elsif ($file !~ /[^\/]\.loc$/) {
        print STDERR "Argument $file is not a .loc file\n";
        $error++;
    }
}
if ($error > 0) {
    print STDERR "$error error" . (($error == 1) ? '' : 's') . " found, abort operation\n";
    exit(1);
}


# find the 'gpsbabel' executable in $PATH
my $gpsbabel = find_in_path('gpsbabel');
if (!$gpsbabel) {
    print STDERR "Cannot find 'gpsbabel' executable in \$PATH\n";
    exit(1);
}





# now convert every file
my $found_files = 0;
my $converted_files = 0;
foreach my $file (@ARGV) {
    $found_files++;
    my $in = read_file($file);
    if ($in !~ /src="Groundspeak"/s) {
        print STDERR "Input file ($file) is not a valid .loc file\n";
        exit(1);
    }
    my $id = $in;
    $id =~ s/^.+name id="(GC[A-Z0-9]+)".+$/$1/s;
    if ($id eq $in) {
        print STDERR "Cannot identify ID in $file\n";
        exit(1);
    }
    print "file: $file\n";
    print "  id: $id\n";
    my $in_name = in_name($file, $id);
    print "  in: $in_name\n";
    my $out_name = $in_name;
    $out_name =~ s/\.loc/.gpx/;
    print " out: $out_name\n";
    if (-f $out_name) {
        print "output file does already exist\n";
        next;
    }
    convert_file($file, $id, $in_name, $out_name, $gpsbabel);
    $converted_files++;
}


# statistics ...
print "\n";
print "Found $found_files file" . (($found_files == 1) ? '' : 's') . "\n";
print "Converted $converted_files file" . (($converted_files == 1) ? '' : 's') . "\n";
exit(0);




# convert_file()
#
# convert a .loc file into a .gpx file
#
# parameter:
#  - original filename
#  - Geocaching ID
#  - designated filename with .loc suffix
#  - designated filename with .gpx suffix
#  - path to 'gpsbabel' executable
# return:
#  none
sub convert_file {
    my $file = shift;
    my $id = shift;
    my $in_name = shift;
    my $out_name = shift;
    my $gpsbabel = shift;

    # rename the file, if necessary
    if ($file ne $in_name) {
        if (!rename($file, $in_name)) {
            print STDERR "Cannot rename source file:\n";
            print STDERR "$file -> $in_name\n";
            print STDERR "Error: $!\n";
            exit(1);
        }
    }

    # convert the file, using the GC id
    my $result = system("$gpsbabel -i geo -f " . quotemeta($in_name) . " -o gpx -F " . quotemeta($out_name) . "");
    if ($result != 0) {
        print STDERR "Failed to convert file: $in_name\n";
        exit(1);
    }
}



# read_file()
#
# read in the source file
#
# parameter:
#  - filename
# return:
#  - string with file content
sub read_file {
    my $file = shift;

    my $in = '';
    {
        local $/ = undef;

        my $fh = new FileHandle;
        open($fh, $file);
        if (!$fh) {
            print STDERR "Cannot open file: $file\n";
            print STDERR "Error: $!\n";
            exit(1);
        }
        $in = <$fh>;
        close($fh);
    }

    return $in;
}



# in_name()
#
# calculate the new name, based on the Geocaching id
#
# parameter:
#  - filename
#  - Geocaching id
# return:
#  - new filename
sub in_name {
    my $file = shift;
    my $id = shift;

    my $return = $file;
    if ($file =~ /\//) {
        # contains a directory path
        $return =~ s/^(.+\/)(.+)(\.loc)$/$1$id$3/;
    } else {
        $return = $id . ".loc";
    }

    return $return;
}



# find_in_path()
#
# find an executable in $PATH
#
# parameter:
#  - executable name
# return:
#  - path with executable
#    empty string in case the executable is not found
sub find_in_path {
    my $prog = shift;

    my $found = '';
    for my $path (split /:/, $ENV{PATH}) {
        my $test = $path . '/' . $prog;
        if (-f $test and -x $test) {
            $found = $test;
            last;
        }
    }

    return $found;
}



# help()
#
# display the help
#
# parameter:
#  none
# return:
#  none
sub help {
    print "\n";
    print "$0 <filename>.loc [<filename>.loc]\n";
    print "\n";
    print "Convert Geocaching .loc files into basic .gpx files\n";
    print "Suitable for tools like OsmAnd\n";
    print "This tool needs 'gpsbabel' in \$PATH in order to convert the files\n";
    print "\n";
}
