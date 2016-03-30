;;; -*- Mode: LISP; Syntax: Ansi-common-lisp; Package: HTTP; Base: 10; Patch-File: T -*-
;;; Patch file for CL-HTTP version 70.85
;;; Reason: Function HTTP::CPU-MILLISECONDS:  new.
;;; Function (CLOS:METHOD HTTP::CPU-MILLESECONDS (HTTP::BASIC-SERVER-MIXIN)):  -
;;; Function HTTP::ELAPSED-MILLISECONDS:  -
;;; Function (CLOS:METHOD HTTP::ELAPSED-MILLISECONDS (HTTP::BASIC-SERVER-MIXIN)):  -
;;; Written by JCMa, 10/11/00 20:05:15
;;; while running on FUJI-VLM from FUJI:/usr/lib/symbolics/ComLink-39-8-F-MIT-8-5.vlod
;;; with Open Genera 2.0, Genera 8.5, Documentation Database 440.12,
;;; Logical Pathnames Translation Files NEWEST, CLIM 72.0, Genera CLIM 72.0,
;;; PostScript CLIM 72.0, MAC 414.0, 8-5-Patches 2.19, Statice Runtime 466.1,
;;; Statice 466.0, Statice Browser 466.0, Statice Documentation 426.0, Joshua 237.4,
;;; CLIM Documentation 72.0, Showable Procedures 36.3, Binary Tree 34.0,
;;; Mailer 438.0, Working LispM Mailer 8.0, HTTP Server 70.84,
;;; W3 Presentation System 8.1, CL-HTTP Server Interface 53.0,
;;; Symbolics Common Lisp Compatibility 4.0, Comlink Packages 6.0,
;;; Comlink Utilities 10.3, COMLINK Cryptography 2.0, Routing Taxonomy 9.0,
;;; COMLINK Database 11.26, Email Servers 12.0, Comlink Customized LispM Mailer 7.1,
;;; Dynamic Forms 14.4, Communications Linker Server 39.8,
;;; Lambda Information Retrieval System 22.3, Experimental Genera 8 5 Patches 1.0,
;;; Genera 8 5 System Patches 1.21, Genera 8 5 Mailer Patches 1.1,
;;; Genera 8 5 Joshua Patches 1.0, Genera 8 5 Statice Runtime Patches 1.0,
;;; Genera 8 5 Statice Patches 1.0, Genera 8 5 Statice Documentation Patches 1.0,
;;; Genera 8 5 Clim Patches 1.0, Genera 8 5 Genera Clim Patches 1.0,
;;; Genera 8 5 Postscript Clim Patches 1.0, Genera 8 5 Clim Doc Patches 1.0,
;;; Genera 8 5 Image Substrate Patches 1.0, Genera 8 5 Lock Simple Patches 1.0,
;;; HTTP Proxy Server 5.35, HTTP Client Substrate 3.26, HTTP Client 49.11,
;;; Image Substrate 440.4, Essential Image Substrate 433.0, Ivory Revision 5,
;;; VLM Debugger 329, Genera program 8.16, DEC OSF/1 V4.0 (Rev. 110),
;;; 1280x976 8-bit PSEUDO-COLOR X Screen FUJI:0.0 with 224 Genera fonts (DECWINDOWS Digital Equipment Corporation Digital UNIX V4.0 R1),
;;; Machine serial number -2141189585,
;;; Domain Fixes (from CML:MAILER;DOMAIN-FIXES.LISP.33),
;;; Don't force in the mail-x host (from CML:MAILER;MAILBOX-FORMAT.LISP.24),
;;; Make Mailer More Robust (from CML:MAILER;MAILER-FIXES.LISP.15),
;;; Patch TCP hang on close when client drops connection. (from HTTP:LISPM;SERVER;TCP-PATCH-HANG-ON-CLOSE.LISP.10),
;;; Add CLIM presentation and text style format directives. (from FV:SCLC;FORMAT.LISP.20),
;;; Fix Statice Lossage (from CML:LISPM;STATICE-PATCH.LISP.3),
;;; Make update schema work on set-value attributes with accessor names (from CML:LISPM;STATICE-SET-VALUED-UPDATE.LISP.1),
;;; COMLINK Mailer Patches. (from CML:LISPM;MAILER-PATCH.LISP.107),
;;; Clim patches (from CML:DYNAMIC-FORMS;CLIM-PATCHES.LISP.48),
;;; Domain ad host patch (from W:>reti>domain-ad-host-patch),
;;; Background dns refreshing (from W:>reti>background-dns-refreshing.lisp.6).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:SERVER;SERVER.LISP.876"
  "HTTP:SERVER;SERVER.LISP.877")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.876")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(define-generic cpu-milliseconds (server-client-or-log)
  (:documentation "Returns the milliseconds that SERVER-CLIENT-OR-LOG has been computing."))

;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.876")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(defmethod cpu-milliseconds ((server basic-server-mixin))
  (let ((process (server-process server)))
    (if process
        (truncate (- (process-run-time process) (server-process-start-time server))
		  1000.)
        0)))

;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.876")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(define-generic elapsed-milliseconds (server-client-or-log)
  (:documentation "Returns the elapsed milliseconds that SERVER-CLIENT-OR-LOG has been computing."))

;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.877")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(declaim (inline %server-elapsed-time))

(defun %server-elapsed-time (server)
  (- (get-internal-real-time) (server-start-time server)))

;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.877")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(defmethod elapsed-time ((server basic-server-mixin))
  (%server-elapsed-time server))


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.877")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(defmethod elapsed-seconds ((server basic-server-mixin))
  (truncate (%server-elapsed-time server) internal-time-units-per-second))


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;SERVER.LISP.877")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: lisp; Syntax: ANSI-Common-Lisp; Package: http; Base: 10 -*-")

(defmethod elapsed-milliseconds ((server basic-server-mixin))
  (* (%server-elapsed-time server) #.(float (/ 1000. internal-time-units-per-second))))

