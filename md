# New API for conversion from UTF-8 to UV

## Preamble

    Author:  K. H. Williamson <khw@cpan.org>
    ID:      RFC-0022
    Status:  Draft


## Abstract

Introduce an API more convenient to use safely

## Motivation

The existing API requires disambiguation between a NUL character and malformed
UTF-8, which callers tend to not do, and the caller besides has to take
extra steps to correctly implement current best practices for dealing with
malformed UTF-8.

## Rationale

This API has no ambiguity between success and failure, and always returns 
based on best practices. Other proposals were discarded in the pre-RFC process:
[Pre-RFC: New C API for converting from UTF-8 to code point](http://nntp.perl.org/group/perl.perl5.porters/264207)

## Specification

I think it best to start with just the two functions that will be applicable in
almost all situations.  The pod for these is

=for apidoc      |bool|utf8_to_uvchr       |const char * s|const char * e|UV *cp|Size_t * len
=for apidoc_item |bool|utf8_to_uvchr_nowarn|const char * s|const char * e|UV *cp|Size_t * len

These each translate UTF-8 into UTF-32 (or UTF-64 on platforms where a UV is 64
bits long), returning <true> if the operation succeeded without problems; and
false otherwise.  (Also, they operate on UTF-EBCDIC rather than UTF-8 on
EBCIDIC platforms.)

They differ in how they handle input which results in a <false> return.

More precisely, they each calculate the first code point represented by the
sequence of bytes bounded by <*s> .. <(*e) - 1>, interpreted as UTF-8.
<e> must be strictly greather than <s>; this is asserted for in debugging
builds.

Since UTF-8 is a variable length encoding, the number of bytes examined also
varies.  The algorithm is to first look at <*s>.  If that represents a full
UTF-8 character, no other byte is examined, and the UTF-8 is calculated from
just it.  If more bytes are required to represent a complete UTF-8 character,
<(*s) + 1> is examined as well.  If that isn't enough, <(*s) + 2> is
examined, and so forth, up through <(*e) - 1>, quitting as soon as a
complete character is found.

If the input is valid, <true> is returned; the calculated code point is
stored in <*cp>; and the number of UTF-8 bytes it consumes from <s>, is
stored in <*len>.

If the input is in some way problematic, <false> is returned; the Unicode
REPLACEMENT CHARACTER is stored in <*cp>; and the number of UTF-8 bytes
consumed from <s> is stored in <*len>.  This number will always be > 0, and
is the correct number to add to <s> to continue examining the input for
subsequent characters.  This behavior follows what best practices for handling
malformed UTF-8 have evolved to, based on experiences with security attacks
which use malformations.

Most callers of these function will want to either croak on malformed input or
forge ahead using the returned REPLACEMENT CHARACTER, depending on the
circumstances of the call.  In the latter case, the results won't be "correct",
but will be as good as possible, and would be apparent to anyone examining the
outputs, as the REPLACEMENT CHARACTER has no other use in Unicode than to
signify such an error.

A typical use case for forging ahead no matter what would be:

 while (s < e) {
     UV cp;
     Size_t len;

     (void) utf8_to_uvchr(s, e, &cp, &len);
     // handle the code point

     s += len;
 }

And if the caller wants to do something different when the input isn't valid:

 while (s < e) {
     UV cp;
     Size_t len;

     if (utf8_to_uvchr(s, e, &cp, &len) {
        // handle the code point
     }
     else {
        // croak or recover from the error
     }

     s += len;
 }

C<utf8_to_uvchr> will raise warnings for malformations if UTF8 warnings are
enabled;  C<utf8_to_uvchr_nowarn> will never raise a warning.

Perl extends Unicode to include extra code points.  Neither C<utf8_to_uvchr>
nor C<utf8_to_uvchr_nowarn> will raise warnings for these.

If (unlikely) you need the Unicode code point even on an EBCDIC machine, modify
the success case in the above example to: 

     if (utf8_to_uvchr(s, e, &cp, &len) {
        cp = NATIVE_TO_UNICODE(cp);
     }

(C<REPLACEMENT CHARACTER> is the same in both character sets, so the failure
case doesn't need to be modified.)

## Backwards Compatibility

This is a new interface which I will add support to in Devel::PPPort.  After
that is done, I will issue pull requests to the relatively few places in CPAN
that use the current API.

## Security Implications

This aims to remove any existing security flaws, and to make it easy to fix any
new ones that may come along, without any XS changes.

## Examples

See the Specification

## Prototype Implementation

None; this is just an alternative API to the existing implementation

## Future Scope

After the above is worked through, several more specific functions need to be
added, for situations where non-typical handling is required.

## Rejected Ideas

See [Pre-RFC: New C API for converting from UTF-8 to code point](http://nntp.perl.org/group/perl.perl5.porters/264207)

## Open Issues

Use this to summarise any points that are still to be resolved.

## Copyright

Copyright (C) 2022, K. H. Williamson

This document and code and documentation within it may be used, redistributed and/or modified under the same terms as Perl itself.

