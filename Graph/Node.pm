#-----------------------------------------------------------------------

=head1 NAME

Graph::Node - object class for a node in a directed graph

=head1 SYNOPSIS

   use Graph::Node;
   use Graph::Edge;

   $parent = new Graph::Node('LABEL' => 'Parent Node');
   $child  = new Graph::Node('LABEL' => 'Child Node');
   $edge   = new Graph::Edge('FROM' => $parent,
			     'TO'   => $child);

   $parent->save('simple.daVinci', 'daVinci');

=cut

#-----------------------------------------------------------------------

package Graph::Node;
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Graph::Node> module implements a I<node> in a I<directed graph>.
A graph is constructed using Node and Edge objects;
edges are defined with the Graph::Edge class.

=cut

#-----------------------------------------------------------------------

use IO::File;
use Graph::Element;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw(@ISA $VERSION %drawnNode);

@ISA     = qw(Graph::Element);
$VERSION = '1.001';

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my $DEFAULT_FILE_FORMAT = 'daVinci';
my $nodeCount;

#-----------------------------------------------------------------------

=head1 CONSTRUCTOR

Create a new Node object.
Returns a reference to a Graph::Node object:

   $node = new Graph::Node('ID'    => 'identifier',
			   'LABEL' => 'text string'
			  );

The C<ID> attribute is optional, and must be a unique string identifying
the edge. If you do not specify the C<ID> attribute, the edge will be assigned
a unique identifier automatically.

The C<LABEL> attribute is also optional,
and specifies a text string which should be associated with the node.
This should be used when drawing the Node, for example.

=cut

#-----------------------------------------------------------------------
# This is inherited from Graph::Element
#=======================================================================


#=======================================================================

=head1 METHODS

This class implements the following methods:

=over 4
=item *
B<setAttribute()> - set the value of an attribute on the node
=item *
B<getAttribute()> - get the value of an attribute of the node
=item *
B<save()> - save the graph under the node in a specified file
=back

The save method is described below.
The setAttribute and getAttribute methods are described in the
documentation for the base class Graph::Element,
where they are defined.

=cut

#=======================================================================

#=======================================================================

=head2 save - save directed graph to a file

=over 4

=item $filename

The name or fullpath of the file to save the directed graph into.

=item $format

An optional string which specifies the format which the graph should
be saved as.
At the moment the only format supported is B<daVinci>,
which generates the file format used by the I<daVinci>
graph visualisation system.

=back

The C<save()> method is used to save a directed graph into a file.
At the moment the graph is saved in the format used by the daVinci
graph visualization system (daVinci v2.0).

The filename extension should be I<.daVinci>,
otherwise daVinci will complain.

=cut

#=======================================================================
sub save
{
    my $self	  = shift;
    my $filename  = shift;
    my $format    = shift;

    my $FILEHANDLE;


    #-------------------------------------------------------------------
    # If no file format given, we fall back to default
    #-------------------------------------------------------------------
    $format ||= $DEFAULT_FILE_FORMAT;

    undef %drawnNode;
    $FILEHANDLE = new IO::File("> $filename") || do
    {
	warn "Can't save to $filename: $!\n";
	return;
    };

    if ($format eq 'daVinci')
    {
	print $FILEHANDLE "[\n";
	$self->save_me($FILEHANDLE, $format, 1);
	print $FILEHANDLE "]\n";
    }
}

#=======================================================================
# save_me() - private function which does the work of saving
#    $node       - the node being saved
#    $FILEHANDLE - the file we're saving the graph to
#    $format     - the graph file format to save in
#    $depth      - recursion depth, used to give nice indenting
#=======================================================================
sub save_me
{
    my $node		= shift;
    my $FILEHANDLE	= shift;
    my $format          = shift;
    my $depth           = shift;

    my @edges;
    my $edge;
    my $i;
    my $attributes       = '';


    if ($format eq 'daVinci')
    {
	#-------------------------------------------------------------------
	# If no file format given, we fall back to default
	#-------------------------------------------------------------------
	$format ||= $DEFAULT_FILE_FORMAT;

	print $FILEHANDLE ' ' x $depth;

	if ($drawnNode{$node->id})
	{
	    print $FILEHANDLE "r(\"".$node->id."\")\n";
	    return;
	}
	$drawnNode{$node->id} = 1;

	if (defined $node->label)
	{
	    $attributes .= "a(\"OBJECT\", \"".$node->label."\")";
	}
	print $FILEHANDLE ("l(\"", $node->id, "\", n(\"anything\", ",
			   "[$attributes], [\n");

	#-------------------------------------------------------------------
	# iterate over all edges connected to this node
	#-------------------------------------------------------------------
	if (exists $node->{'EDGES'})
	{
	    @edges = grep($_->from() eq $node, @{$node->{'EDGES'}});

	    for ($i = 0; $i <= $#edges; ++$i)
	    {
		$edge = $edges[$i];
		if ($edge->to() eq $node)
		{
		    $edge->save_me($FILEHANDLE, $format, $depth + 1,
				   "r(\"".$node->id."\")");
		}
		else
		{
		    $edge->save_me($FILEHANDLE, $format, $depth + 1);
		}
		if (@edges > 1 && $i < $#edges)
		{
		    print $FILEHANDLE ' ' x $depth, ",\n";
		}
	    }
	}

	print $FILEHANDLE (' ' x $depth), "]))\n";
    }
}

#=======================================================================
# add_edge() - add an edge to the list associated with a node
#     $self - me
#     $edge - the edge which is being added to the node
#
# This function is called from within the Graph::Edge class whenever
# an edge is created. The add_edge private method is invoked on both
# nodes at either end of the edge. We add the edge to the list of edges
# connected to the node.
#=======================================================================
sub add_edge
{
    my $self	= shift;
    my $edge	= shift;


    $self->{'EDGES'} = [] if !exists $self->{'EDGES'};

    push(@{ $self->{'EDGES'} }, $edge);
}


#-----------------------------------------------------------------------

=head1 SEE ALSO

=over 4

=item Graph::Node

for a description of the Node class.

=item Graph::Element

for a description of the base class, including the attribute methods.

=back

=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

1;
