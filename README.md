Glical: glancing at iCal data using OCaml
=========================================

Description
-----------

Glical  is  a rather  small  library  for  OCaml \[1]  programmers  to
manipulate iCal data.  Since iCalendar  \[2] is gigantic and very hard
if not  virtually impossible  to address  fully, we  here call  iCal a
subset of  iCalendar.  And  since even  iCal is too  big to  really be
addressed, we state that we provide a library that allows to glance at
iCal data.

By "glancing iCal data" we mean  "processing iCal data" with as little
knowledge of  the iCal(endar)  format as  possible.  This  library has
been developed  with the  idea that  very few  properties of  the iCal
format are sufficient  for most people to transform some  iCal data or
extract the information that they want from it.

The core of  this library is implemented in pure  OCaml, with no other
package dependencies nor external dependencies.  This library requires
some features introduced in OCaml 4.01.0  \[3], so it will not compile
with previous versions of the OCaml compiler.

An extension of this library is also provided. It may depend on other
packages, depending on how it evolves.

A  command-line tool  is being  designed  and developed, based  on the
previously mentioned library extension.


\[1]: The OCaml community web site: <http://ocaml.org>

\[2]: F. Dawson  and D. Stenerson, *RFC2445:  Internet Calendaring and
Scheduling    Core    Object   Specification    (iCalendar)*,    1998,
<http://tools.ietf.org/html/rfc2445>

\[3]: OCaml 4.01, <http://caml.inria.fr/pub/distrib/ocaml-4.01/>
<http://caml.inria.fr/pub/distrib/ocaml-4.01/notes/Changes>


Please see PLAY.md for instructions. 

Distribution
------------

The development of this library is at the early stage. 
Do feel free to try it and give feedbacks.

An opam package (named `glical`) is on its way (the first PR has been submitted) for the *library* part.

The command-line tool will be distributed at some point in another package (possibly `glical-tool`).

Contribution
------------

Please feel free to fork this library.
Pull requests are welcome.

Issues
------

Please do feel free to report any bug or any issue on Github's issues
tracker: <https://github.com/pw374/glical/issues>


Licence
-------

This library is  freely distributed under the ISC licence,  which is a
BSD-like licence.


Author
------

Philippe Wang <Philippe.Wang@cl.cam.ac.uk>




