#-----------------------------------------------------------------------

=head1 NAME

Graph::Edge - object class for an edge in a directed graph

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

package Graph::Edge;
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Graph::Edge> is a class implementing an edge, or arc,
in a directed graph.
A graph is constructed using Node and Edge objects, with nodes being
defined with the Graph::Node class.

An Edge takes four standard attributes: B<ID>, B<LABEL>, B<FROM>,
and B<TO>. In addition, you may also define any number of custom
attributes.
Attributes are manipulated using the setAttribute,
getAttribute methods, which are defined in the base class, Graph::Element.

=cut

#-----------------------------------------------------------------------

use IO::File;
use Graph::Element;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw(@ISA $VERSION);

@ISA     = qw(Graph::Element);
$VERSION = '1.001';

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my $edgeCount;

#=======================================================================

=head2 CONSTRUCTOR

    $edge = new Graph::Edge( . . . );

This creates a new instance of the Graph::Edge object class,
used in conjunction with the Graph::Node class to construct
directed graphs.

You B<must> specify the C<FROM> and C<TO> attributes of an edge
when creating it:

   $edge = new Graph::Edge('FROM'  => $parent,
			   'TO'    => $child,
			   'ID'    => 'identifier'
			  );

where the C<$parent> and C<$child> are Graph::Node objects.
The C<ID> attribute is optional, and must be a unique string
identifying the edge.
If you do not specify the C<ID> attribute, the edge will be assigned
a unique identifier automatically.

=cut

#-----------------------------------------------------------------------
# This is inherited from Graph::Element
#=======================================================================


#=======================================================================
# initialise() - initialise an instance of this class
#=======================================================================
sub initialise
{
    my $self        = shift;
    my $optref      = shift;

    my $attribute;


    #-------------------------------------------------------------------
    # Add callback functions for the FROM and TO attributes.
    # MUST do this before setting any attributes ;-)
    #-------------------------------------------------------------------
    $self->addAttributeCallback('FROM', \&attribute_callback);
    $self->addAttributeCallback('TO',   \&attribute_callback);

    #-------------------------------------------------------------------
    # Call initialise() in our SUPERclass, to do standard initialisation
    # of Graph::Element. This does all attribute setting, etc.
    #-------------------------------------------------------------------
    $self->SUPER::initialise($optref);

    return $self;
}

#=======================================================================
# attribute_callback - attribute callback for when TO/FROM change
#    $self      - instance of Graph::Node
#    $attribute - attribute name
#    $value     - new value of the attribute
#
# This callback function is invoked whenever the TO or FROM attributes
# are changed on an Edge object. We then invoke the private(ish)
# method add_edge on the relevant Node object, so it knows to add the
# edge to its list of connected edges.
#=======================================================================
sub attribute_callback
{
    my $self      = shift;
    my $attribute = shift;
    my $value     = shift;

    my $oend;


    #-------------------------------------------------------------------
    # record on the node that the edge is connected to it.
    # Don't bother doing this for self edges
    #-------------------------------------------------------------------
    if ($attribute eq 'FROM' || $attribute eq 'TO')
    {
	$oend = ($attribute eq 'FROM' ? $self->to : $self->from);
	return unless defined $oend;
	$value->add_edge($self) unless $value eq $oend;
    }
}

#=======================================================================
# save_me() - save ourself into the file passed
#    $node       - the node being saved
#    $FILEHANDLE - the file we're saving the graph to
#    $format     - the graph file format to save in
#    $depth      - recursion depth, used to give nice indenting
#    $node       - optional argument, name of node we're pointing to
#
# This function renders an edge into the file $FILEHANDLE,
# using the graph file format specified in the $format argument.
# The $node argument, which is optional, can be used to specify the
# "other end" of the edge, which is used for specifying the reference
# in the case of a "self edge", where the FROM and TO are the same node.
#=======================================================================
sub save_me
{
    my $self	    = shift;
    my $FILEHANDLE  = shift;
    my $format      = shift;
    my $depth       = shift;
    my $node	    = shift;


    if ($format eq 'daVinci')
    {
	my $attributes  = '';		# this for edge attributes


	print $FILEHANDLE (' ' x $depth,
			   "l(\"", $self->id, "\", e(\"anything\", ",
			   "[$attributes],\n");
	if (defined $node)
	{
	    print $FILEHANDLE $node;
	}
	else
	{
	    $self->to->save_me($FILEHANDLE, $format, $depth + 1);
	}
	print $FILEHANDLE ' ' x $depth, "))\n";
    }
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
