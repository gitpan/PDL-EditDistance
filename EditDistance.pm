
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::EditDistance;

@EXPORT_OK  = qw(   edit_costs  _edit_costs  edit_costs_static  edit_distance_full  _edit_distance_full PDL::PP _edit_distance_full  edit_align_full  _edit_align_full PDL::PP _edit_align_full  edit_distance_static  _edit_distance_static PDL::PP _edit_distance_static  edit_align_static  _edit_align_static PDL::PP _edit_align_static  align_op_insert1 PDL::PP align_op_insert1  align_op_insert2 PDL::PP align_op_insert2  align_op_match PDL::PP align_op_match  align_op_substitute PDL::PP align_op_substitute  align_ops  edit_bestpath  _edit_bestpath PDL::PP _edit_bestpath  edit_pathtrace  _edit_pathtrace PDL::PP _edit_pathtrace  edit_lcs  _edit_lcs PDL::PP _edit_lcs  lcs_backtrace  _lcs_backtrace PDL::PP _lcs_backtrace );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::EditDistance::VERSION = 0.05003;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::EditDistance $VERSION;




use strict;

=pod

=head1 NAME

PDL::EditDistance - Wagner-Fischer edit distance and alignment for PDLs.

=head1 SYNOPSIS

 use PDL;
 use PDL::EditDistance;

 ##-- input PDLs
 $a = pdl([map { ord($_) } qw(G U M B O)]);
 $b = pdl([map { ord($_) } qw(G A M B O L)]);

 $a1 = pdl([0, map { ord($_) } qw(G U M B O)]);
 $b1 = pdl([0, map { ord($_) } qw(G A M B O L)]);

 ##-------------------------------------------------------------
 ## Levenshtein distance
 $dist          = edit_distance_static($a,$b, 0,1,1);
 ($dist,$align) = edit_align_static($a,$b, 0,1,1);

 ##-------------------------------------------------------------
 ## Wagner-Fischer distance
 @costs         = ($costMatch=0,$costInsert=1,$costSubstitute=2);
 $dist          = edit_distance_static($a,$b, @costs);
 ($dist,$align) = edit_align_static($a,$b, @costs);

 ##-------------------------------------------------------------
 ## General edit distance
 $costsMatch = random($a->nelem+1, $b->nelem+1);
 $costsIns   = random($a->nelem+1, $b->nelem+1);
 $costsSubst = random($a->nelem+1, $b->nelem+1);
 @costs         = ($costsMatch,$costsIns,$costsSubst);
 $dist          = edit_distance_full($a,$b,@costs);
 ($dist,$align) = edit_align_full($a,$b,@costs);

 ##-------------------------------------------------------------
 ## Alignment
 $op_match = align_op_match();      ##-- constant
 $op_ins1  = align_op_insert1();    ##-- constant
 $op_ins2  = align_op_insert2();    ##-- constant
 $op_subst = align_op_substitute(); ##-- constant

 ($apath,$bpath,$pathlen) = edit_bestpath($align);
 ($ai,$bi,$ops,$pathlen)  = edit_pathtrace($align);

 ##-------------------------------------------------------------
 ## Longest Common Subsequence
 $lcs = edit_lcs($a,$b);
 ($ai,$bi,$lcslen) = lcs_backtrace($a,$b,$lcs);

=cut







=head1 FUNCTIONS



=cut






=pod

=head2 _edit_pdl

=for sig

  Signature: (a(N); [o]apdl(N+1))

Convenience method.
Returns a pdl $apdl() suitable for representing $a(),
which can be specified as a string, arrays of numbers, or as a PDL.
$apdl(0) is always set to zero.

=cut

sub _edit_pdl {
  return $_[0]->flat->reshape($_[0]->nelem+1)->rotate(1) if (UNIVERSAL::isa($_[0],'PDL'));
  return pdl(byte,[0, map { ord($_) } split(//,$_[0])]) if (!ref($_[0]));
  return pdl([0,@{$_[0]}]);
}





=pod

=head2 edit_costs

=for sig

  Signature: (PDL::Type type; int N; int M;
              [o]costsMatch(N+1,M+1); [o]costsIns(N+1,M+1); [o]costsSubst(N+1,M+1))

Convenience method.
Ensures existence and proper dimensionality of cost matrices for inputs
of length N and M.

=cut

sub edit_costs {
  return _edit_costs($_[0],$_[1]+1,$_[2]+1,@_[3..$#_]);
}





=pod

=head2 _edit_costs

=for sig

  Signature: (PDL::Type type; int N1; int M1;
              [o]costsMatch(N1,M1); [o]costsIns(N1,M1); [o]costsSubst(N1,M1))

Low-level method.
Ensures existence and proper dimensionality of cost matrices for inputs
of length N1-1 and M1-1.

=cut

sub _edit_costs {
  #my ($type,$n1,$m1,$costsMatch,$costsIns,$costsSubst) = @_;
  return (_edit_matrix(@_[0..2],$_[3]),
          _edit_matrix(@_[0..2],$_[4]),
          _edit_matrix(@_[0..2],$_[5]));
}

##-- $matrix = _edit_matrix($type,$dim0,$dim1,$mat)
sub _edit_matrix {
  return zeroes(@_[0..2]) if (!defined($_[3]));
  $_[3]->reshape(@_[1,2]) if ($_[3]->ndims != 2 || $_[3]->dim(0) != $_[1] || $_[3]->dim(1) != $_[2]);
  return $_[3]->type == $_[0] ? $_[3] : $_[3]->convert($_[0]);
}




=pod

=head2 edit_costs_static

=for sig

  Signature: (PDL::Type type; int N; int M;
              staticCostMatch(); staticCostIns(); staticCostSubst();
              [o]costsMatch(N+1,M+1); [o]costsIns(N+1,M+1); [o]costsSubst(N+1,M+1))

Convenience method.

=cut

sub edit_costs_static {
  #my ($type,$n,$m,$cMatch,$cIns,$cSubst,$costsMatch,$costsIns,$costsSubst) = @_;
  my @costs = edit_costs(@_[0..2],@_[6..$#_]);
  $costs[$_] .= $_[$_+3] foreach (0..2);
  return @costs;
}




=pod

=head2 edit_distance_full

=for sig

  Signature: (a(N); b(M);
              costsMatch(N+1,M+1); costsIns(N+1,M+1); costsSubst(N+1,M+1);
              [o]dist(N+1,M+1); [o]align(N+1,M+1))

Convenience method.
Compute the edit distance matrix for inputs $a() and $b(), and
cost matrices $costsMatch(), $costsIns(), and $costsSubst().
$a() and $b() may be specified as PDLs, arrays of numbers, or as strings.

=cut

sub edit_distance_full {
  return _edit_distance_full(_edit_pdl($_[0]), _edit_pdl($_[1]), @_[2..$#_]);
}





=head2 _edit_distance_full

=for sig

  Signature: (a1(N1); b1(M1); costsMatch(N1,M1); costsIns(N1,M1); costsSubst(N1,M1); [o]dist(N1,M1))


Low-level method.
Compute the edit distance matrix for input PDLs $a1() and $b1() and
cost matrices $costsMatch(), $costsIns(), and $costsSubst().

The first elements of $a1() and $b1() are ignored.


=for bad

_edit_distance_full does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_distance_full = \&PDL::_edit_distance_full;




=pod

=head2 edit_align_full

=for sig

  Signature: (a(N); b(M);
              costsMatch(N+1,M+1); costsIns(N+1,M+1); costsSubst(N+1,M+1);
              [o]dist(N+1,M+1); [o]align(N+1,M+1))

Convenience method.
Compute the edit distance and alignment matrices for inputs $a() and $b(), and
cost matrices $costsMatch(), $costsIns(), and $costsSubst().
$a() and $b() may be specified as PDLs, arrays of numbers, or as strings.

=cut

sub edit_align_full {
  return _edit_align_full(_edit_pdl($_[0]), _edit_pdl($_[1]), @_[2..$#_]);
}





=head2 _edit_align_full

=for sig

  Signature: (a1(N1); b1(M1); costsMatch(N1,M1); costsIns(N1,M1); costsSubst(N1,M1); [o]dist(N1,M1); byte [o]align(N1,M1))


Low-level method.
Compute the edit distance and alignment matrix for input PDLs $a1() and $b1() and
cost matrices $costsMatch(), $costsIns(), and $costsSubst().

The first elements of $a1() and $b1() are ignored.


=for bad

_edit_align_full does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_align_full = \&PDL::_edit_align_full;




=pod

=head2 edit_distance_static

=for sig

  Signature: (a(N); b(M);
              staticCostMatch(); staticCostIns(); staticCostSubst();
              [o]dist(N+1,M+1))

Convenience method.
Compute the edit distance matrix for inputs $a() and $b() given
a static cost schema @costs = ($staticCostMatch(), $staticCostIns(), and $staticCostSubst()).
$a() and $b() may be specified as PDLs, arrays of numbers, or as strings.
Functionally equivalent to edit_distance_full($matches,@costs,$dist),
but slightly faster.

=cut

sub edit_distance_static {
  return _edit_distance_static(_edit_pdl($_[0]), _edit_pdl($_[1]), @_[2..$#_]);
}





=head2 _edit_distance_static

=for sig

  Signature: (a1(N1); b1(M1); costMatch(); costIns(); costSubst(); [o]dist(N1,M1))


Low-level method.
Compute the edit distance matrix for input PDLs $a1() and $b1() given a
static cost schema @costs = ($costMatch(), $costIns(), $costSubst()).
Functionally identitical to _edit_distance_matrix_full($matches,@costs,$dist),
but slightly faster.

The first elements of $a1() and $b1() are ignored.


=for bad

_edit_distance_static does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_distance_static = \&PDL::_edit_distance_static;




=pod

=head2 edit_align_static

=for sig

  Signature: (a(N); b(M);
              staticCostMatch(); staticCostIns(); staticCostSubst();
              [o]dist(N+1,M+1); [o]align(N+1,M+1))

Convenience method.
Compute the edit distance and alignment matrices for inputs $a() and $b() given
a static cost schema @costs = ($staticCostMatch(), $staticCostIns(), and $staticCostSubst()).
$a() and $b() may be specified as PDLs, arrays of numbers, or as strings.
Functionally equivalent to edit_align_full($matches,@costs,$dist),
but slightly faster.

=cut

sub edit_align_static {
  return _edit_align_static(_edit_pdl($_[0]), _edit_pdl($_[1]), @_[2..$#_]);
}





=head2 _edit_align_static

=for sig

  Signature: (a1(N1); b1(M1); costMatch(); costIns(); costSubst(); [o]dist(N1,M1); byte [o]align(N1,M1))


Low-level method.
Compute the edit distance and alignment matrices for input PDLs $a1() and $b1() given a
static cost schema @costs = ($costMatch(), $costIns(), $costSubst()).
Functionally identitical to _edit_distance_matrix_full($matches,@costs,$dist),
but slightly faster.

The first elements of $a1() and $b1() are ignored.


=for bad

_edit_align_static does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_align_static = \&PDL::_edit_align_static;





=head2 align_op_insert1

=for sig

  Signature: ([o]a())

=for ref

Alignment matrix value constant for insertion operations on $a() string.

=for bad

align_op_insert1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*align_op_insert1 = \&PDL::align_op_insert1;





=head2 align_op_insert2

=for sig

  Signature: ([o]a())

=for ref

Alignment matrix value constant for insertion operations on $a() string.

=for bad

align_op_insert2 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*align_op_insert2 = \&PDL::align_op_insert2;





=head2 align_op_match

=for sig

  Signature: ([o]a())

=for ref

Alignment matrix value constant for matches.

=for bad

align_op_match does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*align_op_match = \&PDL::align_op_match;





=head2 align_op_substitute

=for sig

  Signature: ([o]a())

=for ref

Alignment matrix value constant for substitution operations.

=for bad

align_op_substitute does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*align_op_substitute = \&PDL::align_op_substitute;



=pod

=head2 align_ops

=for sig

  Signature: ([o]ops(4))

Alignment matrix value constants 4-element pdl (match,insert1,insert2,substitute).a

=cut

sub align_ops { return PDL->sequence(PDL::byte(),4); }




=pod

=head2 edit_bestpath

=for sig

  Signature: (align(N+1,M+1); [o]apath(N+M+2); [o]bpath(N+M+2); [o]pathlen())

Convenience method.
Compute best path through alignment matrix $align().
Stores paths for original input strings $a() and $b() in $apath() and $bpath()
respectively.
Negative values in $apath() and $bpath() indicate insertion/deletion operations.
On completion, $pathlen() holds the actual length of the paths.

=cut

sub edit_bestpath {
  my ($align,$apath,$bpath,$len) = @_;
  $len=pdl(long,$align->dim(0)+$align->dim(1)) if (!defined($len));
  if (!defined($apath)) { $apath=zeroes(long,$len); }
  else { $apath->reshape($len) if ($apath->nelem < $len); }
  if (!defined($bpath)) { $bpath = zeroes(long,$len); }
  else { $bpath->reshape($len) if ($bpath->nelem < $len); }
  _edit_bestpath($align, $apath, $bpath, $len, $align->dim(0)-1, $align->dim(1)-1);
  return ($apath,$bpath,$len);
}





=head2 _edit_bestpath

=for sig

  Signature: (align(N1,M1); int [o]apath(L); int [o]bpath(L); int [o]len(); int ifinal; int jfinal)


Low-level method.
Compute best path through alignment matrix $align() from final index ($ifinal,$jfinal).
Stores paths for (original) input strings $a() and $b() in $apath() and $bpath()
respectively.
Negative values in $apath() and $bpath() indicate insertion/deletion operations.
On completion, $pathlen() holds the actual length of the paths.


=for bad

_edit_bestpath does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_bestpath = \&PDL::_edit_bestpath;




=pod

=head2 edit_pathtrace

=for sig

  Signature: ( align(N+1,M+1); [o]ai(L); [o]bi(L); [o]ops(L); [o]$pathlen() )

Convenience method.
Compute alignment path backtrace through alignment matrix $align() from final index ($ifinal,$jfinal).
Stores raw paths for (original) input strings $a() and $b() in $ai() and $bi()
respectively.
Unlike edit_bestpath(), null-moves for $ai() and $bi() are not stored here as negative values.
Returned pdls ($ai,$bi,$ops) are trimmed to the appropriate path length.

=cut

sub edit_pathtrace {
  my ($align,$ai,$bi,$ops,$len) = @_;
  $len=pdl(long,$align->dim(0)+$align->dim(1)) if (!defined($len));
  if (!defined($ai)) { $ai=zeroes(long,$len); }
  else { $ai->reshape($len) if ($ai->nelem < $len); }
  if (!defined($bi)) { $bi = zeroes(long,$len); }
  else { $bi->reshape($len) if ($bi->nelem < $len); }
  if (!defined($ops)) { $ops = zeroes(long,$len); }
  else { $ops->reshape($len) if ($ops->nelem < $len); }
  _edit_pathtrace($align, $ai,$bi,$ops,$len, $align->dim(0)-1,$align->dim(1)-1);
  my $lens = ($len->sclr-1);
  return ((map { $_->slice("0:$lens") } ($ai,$bi,$ops)), $len);
}





=head2 _edit_pathtrace

=for sig

  Signature: (align(N1,M1); int [o]ai(L); int [o]bi(L); int [o]ops(L); int [o]len(); int ifinal; int jfinal)


Low-level method.
Compute alignment path backtrace through alignment matrix $align() from final index ($ifinal,$jfinal).
Stores raw paths for (original) input strings $a() and $b() in $ai() and $bi()
respectively.
Unlike edit_bestpath(), null-moves for $ai() and $bi() are not stored here as negative values.
Returned pdls ($ai,$bi,$ops) are trimmed to the appropriate path length.


=for bad

_edit_pathtrace does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_pathtrace = \&PDL::_edit_pathtrace;




=pod

=head2 edit_lcs

=for sig

  Signature: (a(N); b(M); int [o]lcs(N+1,M+1);)

Convenience method.
Compute the longest common subsequence (LCS) matrix for input PDLs $a1() and $b1().
The output matrix $lcs() contains at cell ($i+1,$j+1) the length of the LCS
between $a1(0..$i) and $b1(0..$j); thus $lcs($N,$M) contains the
length of the LCS between $a() and $b().

=cut

sub edit_lcs {
  return _edit_lcs(_edit_pdl($_[0]), _edit_pdl($_[1]), @_[2..$#_]);
}





=head2 _edit_lcs

=for sig

  Signature: (a1(N1); b1(M1); int [o]lcs(N1,M1))


Low-level method.
Compute the longest common subsequence (LCS) matrix for input PDLs $a1() and $b1().
The initial (zeroth) elements of $a1() and $b1() are ignored.
The output matrix $lcs() contains at cell ($i,$j) the length of the LCS
between $a1(1..$i) and $b1(1..$j); thus $lcs($N1-1,$M1-1) contains the
length of the LCS between $a1() and $b1().


=for bad

_edit_lcs does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_edit_lcs = \&PDL::_edit_lcs;




=pod

=head2 lcs_backtrace

=for sig

  Signature: (a(N); b(M); int lcs(N+1,M+1); int ifinal(); int jfinal(); int [o]ai(L); int [o]bi(L); int [o]len())

Convenience method.
Compute longest-common-subsequence backtrace through LCS matrix $lcs()
for original input strings ($a(),$b()) from final index ($ifinal,$jfinal).
Stores raw paths for (original) input strings $a() and $b() in $ai() and $bi()
respectively.

=cut

sub lcs_backtrace {
  my ($a,$b,$lcs,$ifinal,$jfinal,$ai,$bi,$len) = @_;
  $len=pdl(long, pdl(long,$lcs->dims)->min) if (!defined($len));
  if (!defined($ai)) { $ai=zeroes(long,$len); }
  else { $ai->reshape($len) if ($ai->nelem < $len); }
  if (!defined($bi)) { $bi = zeroes(long,$len); }
  else { $bi->reshape($len) if ($bi->nelem < $len); }
  if (!defined($ifinal)) { $ifinal = $lcs->dim(0)-1; }
  if (!defined($jfinal)) { $jfinal = $lcs->dim(1)-1; }
  _lcs_backtrace(_edit_pdl($a),_edit_pdl($b), $lcs,$ifinal,$jfinal, $ai,$bi,$len);
  my $lens = ($len->sclr-1);
  return ($ai->slice("0:$lens"),$bi->slice("0:$lens"), $len);
}





=head2 _lcs_backtrace

=for sig

  Signature: (a1(N1); b1(M1); int lcs(N1,M1); int ifinal(); int jfinal(); [o]ai(L); [o]bi(L); int [o]len())


Low-level method.
Compute longest-common-subsequence backtrace through LCS matrix $lcs()
for initial-padded strings ($a1(),$b1()) from final index ($ifinal,$jfinal).
Stores raw paths for (original) input strings $a() and $b() in $ai() and $bi()
respectively.


=for bad

_lcs_backtrace does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*_lcs_backtrace = \&PDL::_lcs_backtrace;




##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Probably many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2006, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1), PDL(3perl).

=cut



;



# Exit with OK status

1;

		   