(* -*- coding: utf-8; -*- *)
(* ********************************************************************* *)
(* glical: A library to glance at iCal data using OCaml                  *)
(* (c) 2013/2014, Philippe Wang <philippe.wang@cl.cam.ac.uk>             *)
(* Licence: ISC                                                          *)
(* ********************************************************************* *)

open Printf
include Glical_kernel
open Ical

module SSet = Set.Make(String)

let channel_contents ic =
  let b = Buffer.create 42 in
  begin
    try
      while true do
        Buffer.add_char b (input_char ic)
      done with End_of_file -> ()
  end;
  Buffer.contents b

let simple_cat ic oc =
  let s = channel_contents ic in
  let l = lex_ical s in
  let p : 'a Ical.t = parse_ical l in
  let d = Datetime.parse_datetime p in
  let o =
    to_string
      ~f:(function
          | (`Text _ | `Raw _) -> None
          | `Datetime d -> Some(Datetime.to_string d)
        ) d in
  fprintf oc "%s%!" o


let to_socaml ?(f=(fun _ -> None)) t =
  let b = Buffer.create 42 in
  let (!!) s =
    let s = String.copy s in
    for i = 0 to String.length s - 1 do
      match s.[i] with
      | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> ()
      | _ -> s.[i] <- '_'
    done;
    s
  in
  let rec loop = function
    | [] -> ()
    | Block(_, s, v)::tl ->
      bprintf b "module M_%s = struct\n" !!s;
      loop v;
      bprintf b "end (*M_%s*)\n" !!s;
      loop tl
    | Assoc(_, s, r)::tl ->
      (match f r with
         | Some x ->
           bprintf b "let v_%s = %S\n" !!s x
         | None ->
           match r with
           | `Text(loc, xtl) ->
             bprintf b "let v_%s = [%S]\n" !!s
               (List.fold_left
                  (fun r e -> r ^ sprintf "; %S" e)
                  ""
                  xtl)
           | `Raw(loc, x) ->
             bprintf b "let v_%s = %S\n" !!s x
           | _ -> ());
      loop tl
  in
  loop t;
  Buffer.contents b


let to_docaml ?(f=(fun _ -> None)) t =
  let open Buffer in
  let b = Buffer.create 42 in
  let add_spaces n =
    for i = 1 to n do
      Buffer.add_char b ' '
    done
  in
  let rec loop indent = function
    | [] -> ()
    | Block((l, c), s, v)::tl ->
      add_spaces indent;
      bprintf b "Block((%d, %d), %S, [\n" l c s;
      loop (indent+2) v;
      add_spaces indent;
      bprintf b "]);\n";
      loop indent tl
    | Assoc((l, c), s, r)::tl ->
      add_spaces indent;
      (match f r with
         | Some x ->
           bprintf b "Assoc((%d, %d), %S, %s);" l c s x;
         | None ->
           match r with
           | `Text((ll, cc), xtl) ->
             bprintf b "Assoc((%d, %d), %S, `Text((%d, %d), [" l c s ll cc;
             List.iter
               (fun e -> bprintf b "; %S" e)
               xtl;
             bprintf b "]);";
           | `Raw((ll, cc), x) ->
             bprintf b "Assoc((%d, %d), %S, `Raw((%d, %d), %S));\n"
               l c s ll cc x
           | _ -> ());
      loop indent tl
  in
  add_string b "[\n";
  loop 2 t;
  add_string b "]\n";
  contents b


let extract_assocs ?(kl=[]) ?(ks=SSet.empty) ?k ical : 'a t =
  (* [block] is necessary for performance issues, otherwise
     calling [extract_assocs] would have been sufficient. *)
  let rec block ?(kl=[]) ?(ks=SSet.empty) ?(k=None) = function
    | [] -> false
    | Block(_, _, l) :: tl -> block ~kl ~ks ~k l || block ~kl ~ks ~k tl
    | Assoc(_, key, _)::tl ->
      Some key = k || SSet.mem key ks || List.mem key kl
      || block ~kl ~ks ~k tl
  in
  let i =
    filter
      (function
        | Block(_, _, l) -> block ~kl ~ks ~k l
        | Assoc(_, key, _) ->
          Some key = k || SSet.mem key ks || List.mem key kl)
      ical
  in
  i

let extract_values ?(kl=[]) ?(ks=SSet.empty) ?k ical : 'value list =
  match k with
  | None ->
    fold_on_assocs
      (fun accu key value -> value::accu)
      []
      (extract_assocs ~kl ~ks ical)
  | Some k ->
    fold_on_assocs
      (fun accu key value -> value::accu)
      []
      (extract_assocs ~kl ~ks ~k ical)

let list_keys_rev ical : string list =
  let ks = ref SSet.empty in
  let res = ref [] in
  iter
    (function
        Block _ -> ()
      | Assoc(loc, k, _) ->
        if SSet.mem k !ks then
          ()
        else
          (ks := SSet.add k !ks;
           res := k :: !res))
    ical;
  !res

let list_keys ical : string list =
  List.rev (list_keys_rev ical)


let list_keys_ordered ?(compare=String.compare) ical : string list =
  let
    module SSet = Set.Make(struct type t = string let compare = compare end)
  in
  let ks = ref SSet.empty in
  iter
    (function
        Block _ -> ()
      | Assoc(loc, k, _) ->
        if SSet.mem k !ks then
          ()
        else
          ks := SSet.add k !ks)
    ical;
  SSet.elements !ks


let combine ical1 ical2 : 'a t =
  match ical1, ical2 with
  | [Block(locx, x, xc)], [Block(locy, y, yc)] when x = y ->
    [Block(locx, x, xc@yc)]
  | [], _ -> ical2
  | _, [] -> ical1
  | _ -> ical1 @ ical2


let rec combine_many = function
  | [] -> []
  | [ical] -> ical
  | ical1::ical2::tl ->
    combine_many ((combine ical1 ical2)::tl)


(* ********************************************************************* *)
(* Permission to use, copy, modify, and/or distribute this software
   for any purpose with or without fee is hereby granted, provided
   that the above copyright notice and this permission notice appear
   in all copies.

   THE SOFTWARE IS PROVIDED “AS IS” AND ISC DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL ISC BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
   DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
   WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
   ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
   OF THIS SOFTWARE.                                                     *)
(* ********************************************************************* *)
