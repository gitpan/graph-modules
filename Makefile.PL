#
# Makefile.PL for Graph:: modules distribution
#
# Filename:	Makefile.PL
# Author:	Neil Bowers
# Created:	16 January 1997
# Version:	$Id$
#

use ExtUtils::MakeMaker;


$RCS_ID = '$Id$ ';

&WriteMakefile(
               NAME          => 'Graph',
               DISTNAME      => 'graph-modules',
               VERSION_FROM  => 'Graph/Node.pm',
               dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );
 
