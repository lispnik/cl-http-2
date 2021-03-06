;;;-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: common-lisp-user -*-
;;;
;;; Copyright 1994-95, 2005-2006, John C. Mallery.
;;; All rights reserved.
;;;------------------------------------------------------------------- 
;;;
;;; INITIALIZES CL-HTTP FOR INTERNET OPERATION
;;;

;; If you load this file, you can access the URL
;; http://your.host.domain.name/ and peruse the server documentation,
;; assuming a network connection. See the other init files if you are running
;; over an AppleTalk network, or have no Domain Name Service.

(in-package :cl-user) 

;; options are :load :compile :eval-load :compile-load-always, :compile-load
(define-system 
  (cl-http-demo)
  (:eval-load)
  "http:examples;configuration"         ; server configuration file
  "http:mcl;examples;sysdcl"                ; server example system
  "http:examples;example-exports")              ; server example exports

