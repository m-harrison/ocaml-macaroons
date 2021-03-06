(* The MIT License (MIT)

   Copyright (c) 2015 Nicolas Ojeda Bar <n.oje.bar@gmail.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. *)

(** Macaroons *)

module type CRYPTO = sig
  val hmac : key:string -> string -> string
  (** [hmac ~key m] computes an HMAC of the message [m] using the key [key]. *)

  val hash : string -> string
  (** [hash m] hashes [m]. *)

  val encrypt : key:string -> string -> string
  (** [encrypt ~key m] symmetrically encrypts message [m] under key [key]. *)

  val decrypt : key:string -> string -> string
  (** [decrypt ~key m] symmetrically decrypts message [m] under key [key]. *)
end

module type S = sig
  type t
  (** The type of macaroons. *)

  val create : location:string -> key:string -> id:string -> t

  val location : t -> string
  (** [location m] is the {e location} of [m] (if any). *)

  val identifier : t -> string
  (** [identifier m] is the {e identifier} of [m]. *)

  val signature : t -> string
  (** [signature m] is the {e signature} of [m]. *)

  val add_first_party_caveat : t -> string -> t
  (** [add_first_party_caveat m cid] adds a caveat which will be discharged by
      the target service.  See {!verify}. *)

  val add_third_party_caveat : t -> key:string -> ?location:string -> string -> t
  (** [add_third_party_caveat m ~key ~location cid] adds a caveat that will be
      discharged by a third-party.  The third party is to produce, upon request,
      a macaroon proving that the caveat has been discharged.  This hypothetical
      macaroon must be minted with root key [key].  See {!verify}. *)

  val prepare_for_request : t -> t -> t
  (** [prepare_for_request m d] should be invoke for each discharge macaroon [d]
      associated to the main authorizing macaroon [m] before sending them off
      the target service for verification.  It binds the the signatures of [d]
      and [m] together making it impossible for a malicious third party to
      maliciously re-use [d] to discharge third-party caveats of [m]. *)

  val equal : t -> t -> bool
  (** Whether two macaroons are equal. *)

  val serialize : t -> string
  (** [serialize m] converts the macaroon [m] into a base64-string suitable for
      transmission over the network.  Its inverse is {!deserialize}. *)

  type deserialize_error =
    [ `Unexpected_char of char * char
    | `Not_enough_data of int
    | `Unexpected_packet_id of string
    | `Character_not_found of char ]

  val deserialize : string -> [ `Ok of t | `Error of int * deserialize_error ]
  (** [deserialize m] is the inverse of {!serialize}. *)

  val pp : Format.formatter -> t -> unit
  (** [pp ppf m] prints a user-readable description of the macaroon [m] for
      debugging purposes. *)

  val verify : t -> key:string -> check:(string -> bool) -> t list -> bool
  (** [verify m ~key ~check d] verifies whether all the caveats of [m] hold.
      [key] must be the key used with {!create}.  [check] is called to verify
      all first-party caveats.  [d] is a list of {e discharge} macaroons used to
      verify third-party cavests.  Each element of [d] must have been previously
      bound with [m] using {!prepare_for_request}. *)
end

module Make (C : CRYPTO) : S
(** Macaroons that use [C] for their cryptographic needs. *)
