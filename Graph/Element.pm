#-----------------------------------------------------------------------

=head1 NAME

Graph::Element - base class for elements of a directed graph

=head1 SYNOPSIS

    $object->setAttribute('ATTR_NAME', $value);
    $value = $object->getAttribute('ATTR_NAME');

=cut
#-----------------------------------------------------------------------

package Graph::Element;
require 5.003;
use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Graph::Element> module implements the base class for elements
of a directed graph.
It is subclassed by the B<Graph::Node> and B<Graph::Edge> modules.
This module provides a constructor, and attribute setting mechanisms.

If you want to inherit this class,
see the section below, I<INHERITING THIS CLASS>.

=cut

#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION $AUTOLOAD);

$VERSION = '1.001';

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my %elementCount;


#-----------------------------------------------------------------------

=head2 CONSTRUCTOR

    $edge = new Graph::Element( . . . );

This creates a new instance of the Graph::Element object class,
which is the base class for Graph::Node and Graph::Edge.

You can set attributes of new object by passing arguments to
the constructor.

   $element = new Graph::Element('ATTR1'  => $value1,
		         	 'ATTR2'  => $value2
			        );

If you not set the B<ID> attribute at creation time
a unique value will be automatically assigned.

=cut

#-----------------------------------------------------------------------
sub new
{
    my $class   = shift;
    my %options = @_;

    my $object;


    #-------------------------------------------------------------------
    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.
    #-------------------------------------------------------------------
    $object = bless {}, $class;

    return $object->initialise(\%options);
}

#-----------------------------------------------------------------------

=head1 METHODS

This module provide three methods,
described in separate sections below:

=over 4

=item *

B<setAttribute()>,
which is used to change the value of one or more attribute.

=item *

B<getAttribute()>,
which is used to get the value of exactly one attribute.

=item *

B<addAttributeCallback()>,
which is used to associate a function with a particular object.
The function is then invoked whenever the attribute's is changed.

=back

=cut

#-----------------------------------------------------------------------

#=======================================================================

=head2 setAttribute - change an attribute of an object

    $object->setAttribute('ATTR_A' => $valueA,
                          'ATTR_B' => $valueB);

This method is used to set user-defined attributes on an object. 
These are different from the standard attributes, such as ID
and LABEL.

=cut

#=======================================================================
sub setAttribute
{
    my $self       = shift;
    my %attributes = @_;

    my $key;


    foreach $key (keys %attributes)
    {
	$self->{'_ATTRIBUTES'}->{$key} = $attributes{$key};

	#---------------------------------------------------------------
	# invoke the callback function for the atttribute, if needed
	#---------------------------------------------------------------
	if (defined $self->{'_CALLBACKS'}->{$key})
	{
	    &{ $self->{'_CALLBACKS'}->{$key} }($self, $key, $attributes{$key});
	}
    }

    return 1;
}

#=======================================================================

=head2 getAttribute - query the value of a object's attribute

    $value = $object->getAttribute('ATTRIBUTE_NAME');

This method is used to get the value of a single attribute defined on
an object. If the attribute name given has not been previously set on
the object, B<undef> is returned.

=cut

#=======================================================================
sub getAttribute
{
   my $self      = shift;
   my $attribute = shift;;


   return undef unless exists $self->{'_ATTRIBUTES'};

   return $self->{'_ATTRIBUTES'}->{$attribute};
}

#=======================================================================

=head2 addAttributeCallback - add an attribute callback to object

    $object->addAttributeCallback('ATTR_NAME', \&callback_function);
    
    sub callback_function
    {
        my $self       = shift;
        my $attr_name  = shift;       # name of attribute which changed
        my $attr_value = shift;       # new value of attribute
    
        # do some stuff here
    }

This is used to add a callback function to an object, associated
with a particular attribute. Whenever the attribute is changed,
the callback function is invoked, with the attribute name and new
value passed as arguments.

=cut

#=======================================================================
sub addAttributeCallback
{
    my $self       = shift;
    my $attribute  = shift;
    my $callback   = shift;


    $self->{'_CALLBACKS'}->{$attribute} = $callback;
}

#=======================================================================
# AUTOLOAD() - autoload function, which implements virtual methods
#
#=======================================================================
sub AUTOLOAD
{
    my $attribute = uc($AUTOLOAD);                     # into upper case


    $attribute =~ s/^.*:://;                           # trim package name
    return if $attribute eq 'DESTROY';                 # DESTROY method

    if (@_ == 1)
    {
	return (defined $_[0]->{'_ATTRIBUTES'}->{$attribute}
		? $_[0]->{'_ATTRIBUTES'}->{$attribute}
		: undef);
    }
    else
    {
	return $_[0]->{'_ATTRIBUTES'}->{$attribute} = $_[1];
    }
}

#=======================================================================
# initialise() - initialise a new instance of Graph::Node
#    $self   - instance of Graph::Node
#    $optref - reference to a hash with attribute/value
#
# This function initialises a new instance of the Graph::Node class.
# This consists of setting any attributes passed to the constructor,
# and making sure that the node has a unique ID.
#=======================================================================
sub initialise
{
    my $self   = shift;
    my $optref = shift;

    my $attribute;


    #-------------------------------------------------------------------
    # Set any attributes which were passed to the constructor.
    #-------------------------------------------------------------------
    foreach $attribute (keys %{ $optref })
    {
	$self->setAttribute($attribute, $optref->{$attribute});
    }

    #-------------------------------------------------------------------
    # If the creator did not explicitly pass an ID, then we assign
    # a random unique one.
    #-------------------------------------------------------------------
    if (!defined $self->getAttribute('ID'))
    {
	$self->id($self->generate_id());
    }

    return $self;
}

#=======================================================================
# generate_id() - generate a unique node identifier
#=======================================================================
sub generate_id
{
    my $self = shift;

    my $what = ref($self);


    ++$elementCount{$what};
    return sprintf("$what%.5d", $elementCount{$what});
}


#=======================================================================

=head1 VIRTUAL METHODS FOR ACCESSING ATTRIBUTES

In addition to the C<getAttribute> and C<setAttribute> methods,
this class also supports virtual methods for accessing attributes.

For example, if you have set an attribute B<FOOBAR>,
then you can call method B<foobar()> on the object:

    $object->setAttribute('FOOBAR', $value);
    $value = $object->foobar;

This capability assumes that all attribute names will be in UPPER CASE;
the resulting method names will be all lower case.

This feature is particularly useful for manipulating the B<ID>,
B<LABEL>, B<FROM>, and B<TO> attributes:

    $node->label('label for my node');
    $id = $node->id;
    $edge-to($node);

B<NOTE:> this feature won't work if you use an attribute name which is
the same as an existing method for your object class, such as new,
or DESTROY.

=cut

#=======================================================================


#-----------------------------------------------------------------------

=head1 INHERITING THIS CLASS

If you want to provide attribute methods for your class, you just need
the following lines in your module:

    use Graph::Element;
    @ISA = qw(Graph::Element);

This will give your objects the B<getAttribute()>,
B<setAttribute()>, and B<addAttributeCallback()> methods.

When subclassing Graph::Element you shouldn't need to over-ride
the constructor (B<new()>), but should be able to get away with
over-riding the B<initialise()> function.

=head2 RESTRICTIONS

This class assumes that the object instance for your class is a blessed
hash (associative array) reference.

=head1 SEE ALSO

=over 4

=item Graph::Node

for a description of the Node class.

=item Graph::Edge

for a description of the Edge class.

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
