#!/apps/perl5/bin/perl -w
#
# pmgraph - generate a dependency graph for perl files
#
# Usage: pmgraph.pl [-ascii] foobar.pl
#        pmgraph [ -help | -version ]
#
#        generates <filename>.daVinci
#

require 5.003;
use strict;

use IO::File;
use Graph::Node;
use Graph::Edge;
use Getopt::Long;

use vars qw($VERSION $opt_ascii $opt_verbose);
$VERSION = '1.000';


my $file;
my %edgeTable;
my %seenFile;
my %nodeTable;

&check_switches();

foreach $file (@ARGV)
{
    my $save_file;
    my $root;

    $root = get_node($file);
    &check_file($file, 0);
    ($save_file = "$file.daVinci") =~ s!.*/!!;
    $root->save($save_file, 'daVinci');
    print STDERR "depdendency graph in $save_file\n";
}

#=======================================================================
# check_file() - check a file for any includes, and recurse on those
#=======================================================================
sub check_file
{
    my $checkfile   = shift;
    my $depth       = shift;
    my $report_name = shift;
    my $from        = shift;

    my $FILE;
    my $filename;
    my $fullpath;
    my $inpod;
    my $module;
    my $thisNode;
    my $fromNode;
    my $edge;


    $report_name = $report_name || $checkfile;

    #-------------------------------------------------------------------
    # The check for duplicate edges is needed because some modules have
    # multiple packages in the same module file, with sub-packages
    # defined there. For example, see IO::Socket
    #-------------------------------------------------------------------

    if (defined $from)
    {
	return if defined $edgeTable{"$from\t$report_name"};
	$edgeTable{"$from\t$report_name"} = 1;
	$thisNode = get_node($report_name);
	$fromNode = get_node($from);
	$edge = new Graph::Edge('FROM' => $fromNode,
				'TO'   => $thisNode);
    }

    if (!defined $opt_verbose)
    {
	return if $seenFile{$checkfile};
	$seenFile{$checkfile} = 1;
    }

    if ($opt_ascii)
    {
	print '    ' x $depth, ($depth != 0 ? '-> ' : ''), "$report_name\n";
    }
    if (defined $opt_verbose)
    {
	return if $seenFile{$checkfile};
	$seenFile{$checkfile} = 1;
    }

    $FILE = new IO::File("< $checkfile") || do
    {
	warn "Unable to open $checkfile: $!\n";
	return;
    };
    $inpod = 0;
    while (<$FILE>)
    {
	last if /^__END__/;
	if (/^=(\S+)/)
	{
	    $inpod = 1;
	    $inpod = 0 if $1 eq 'cut';
	    next;
	}
	next if $inpod == 1;
	if (/^\s*require\s+'([^'']+)'/ ||
	   /^\s*require\s+"([^""]+)"/)
	{
	    $filename = $1;
	    $fullpath = find_include($filename);
	    if (defined $fullpath)
	    {
		&check_file($fullpath, $depth + 1, $filename, $report_name);
		# print STDERR "    require $filename [$fullpath]\n";
	    }
	    else
	    {
		print STDERR "    require $filename NOT FOUND!\n";
	    }
	}
	elsif (/^\s*use\s+([^\s;]+)/)
	{
	    $module = $filename = $1;
	    next if $filename =~ /^(strict|vars|subs)$/;
	    $filename .= ".pm";
	    $filename =~ s!::!/!g;
	    $fullpath = find_include($filename);
	    if (defined $fullpath)
	    {
		# print STDERR "    use $filename [$fullpath]\n";
		&check_file($fullpath, $depth + 1, $module, $report_name);
	    }
	    else
	    {
		print STDERR "    use $filename [NOT FOUND]\n";
	    }
	}
    }
    $FILE->close();
}

#=======================================================================
# find_include() - resolve a partial include file into a full path
#=======================================================================
sub find_include
{
    my $filename = shift;

    my $dir;


    foreach $dir (@INC)
    {
	if (-f "$dir/$filename")
	{
	    return "$dir/$filename";
	}
    }
    return undef;
}

#=======================================================================
# get_node() - get a node for the given module, creating it if needs be
#=======================================================================
sub get_node
{
    my $name = shift;


    if (!defined $nodeTable{$name})
    {
	$nodeTable{$name} = new Graph::Node('LABEL' => $name);
    }
    return $nodeTable{$name};
}

#=======================================================================
# check_switches() - check command-line for switches
#=======================================================================
sub check_switches
{
    use vars qw($opt_help $opt_usage $opt_version);
    my @options = ('help', 'usage', 'version', 'ascii', 'verbose');
    my $whatis = 'generate dependency graph for perl source files';
    my $PROGRAM = $0;


    $PROGRAM =~ s!^.*/!!;
    GetOptions(@options) || exit 1;

    #-------------------------------------------------------------------
    # Display message for the -version switch
    #-------------------------------------------------------------------
    if ($opt_version)
    {
	print STDERR "$PROGRAM - $whatis\nVersion: $VERSION\n";
	exit 0;
    }

    #-------------------------------------------------------------------
    # Display message for the -help/-usage switch
    #-------------------------------------------------------------------
    if ($opt_help || $opt_usage)
    {
	print STDERR <<EOFHELP;
$PROGRAM - $whatis
  -ascii   : generate ascii version of tree on STDOUT
  -help    : display a short help message, with all switches [or --usage]
  -verbose : report all occurrences of a module, not just first
  -version : display version message
EOFHELP
        exit 0;
    }

}
