#!/apps/perl5/bin/perl
#
# dgraph.pl - generate directed graph of a directory and sub-directories
#
# Usage: dgraph <directory>
#        results in file dgraph.daVinci
#

use Graph::Node;
use Graph::Edge;

$DIR = $ARGV[0] || '.';

$root = new Graph::Node('LABEL' => "$DIR");
&recurse($DIR, $root);
$root->save('dgraph.daVinci', 'daVinci');

sub recurse
{
   my $directory = shift;
   my $parent    = shift;
   my @children;
   my $child;
   my $childNode;
   my $edge;


   opendir(DIR, $directory) || die "failed to read directory $directory: $!\n";
   @children = grep(-d "$directory/$_" && !/^\.\.?$/, readdir(DIR));
   closedir(DIR);

   foreach $child (@children)
   {
      $childNode = new Graph::Node('LABEL' => $child);
      $edge = new Graph::Edge('FROM' => $parent, 'TO' => $childNode);
      recurse("$directory/$child", $childNode);
   }
}

