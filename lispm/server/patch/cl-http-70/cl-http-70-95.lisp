;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: USER; Base: 10; Patch-File: T -*-
;;; Patch file for CL-HTTP version 70.95
;;; Reason: Variable HTTP::*REMOTE-CONFIGURATION-FORM-PROTOTYPE*:  remove :SECURE-SUBNETS and add :READ-SUBNETS, :WRITE-SUBNETS
;;; Written by Joswig, 12/06/00 20:23:15
;;; while running on FUJI-4 from FUJI:/usr/lib/symbolics/Inc-CL-HTTP-70-90-LMFS.vlod
;;; with Open Genera 2.0, Genera 8.5, Logical Pathnames Translation Files NEWEST,
;;; LMFS 442.1, Color 427.1, Graphics Support 431.0, Genera Extensions 16.0,
;;; Essential Image Substrate 433.0, Color System Documentation 10.0,
;;; SGD Book Design 10.0, Images 431.2, Image Substrate 440.4, CLIM 72.0,
;;; Genera CLIM 72.0, CLX CLIM 72.0, PostScript CLIM 72.0, CLIM Demo 72.0,
;;; CLIM Documentation 72.0, Statice Runtime 466.1, Statice 466.0,
;;; Statice Browser 466.0, Statice Server 466.2, Statice Documentation 426.0,
;;; Metering 444.0, Metering Substrate 444.1, Symbolics Concordia 444.0,
;;; Graphic Editor 440.0, Graphic Editing 441.0, Bitmap Editor 441.0,
;;; Graphic Editing Documentation 432.0, Postscript 436.0,
;;; Concordia Documentation 432.0, Joshua 237.4, Joshua Documentation 216.0,
;;; Joshua Metering 206.0, Jericho 237.0, C 440.0, Lexer Runtime 438.0,
;;; Lexer Package 438.0, Minimal Lexer Runtime 439.0, Lalr 1 434.0,
;;; Context Free Grammar 439.0, Context Free Grammar Package 439.0, C Runtime 438.0,
;;; Compiler Tools Package 434.0, Compiler Tools Runtime 434.0, C Packages 436.0,
;;; Syntax Editor Runtime 434.0, C Library Headers 434,
;;; Compiler Tools Development 435.0, Compiler Tools Debugger 434.0,
;;; C Documentation 426.0, Syntax Editor Support 434.0, LL-1 support system 438.0,
;;; Pascal 433.0, Pascal Runtime 434.0, Pascal Package 434.0, Pascal Doc 427.0,
;;; Fortran 434.0, Fortran Runtime 434.0, Fortran Package 434.0, Fortran Doc 427.0,
;;; HTTP Proxy Server 6.3, HTTP Server 70.94, Showable Procedures 36.3,
;;; Binary Tree 34.0, W3 Presentation System 8.1, HTTP Client Substrate 4.1,
;;; HTTP Client 50.0, Experimental Genera 8 5 Patches 1.0,
;;; Genera 8 5 System Patches 1.21, Genera 8 5 Metering Patches 1.0,
;;; Genera 8 5 Joshua Patches 1.0, Genera 8 5 Jericho Patches 1.0,
;;; Genera 8 5 Joshua Doc Patches 1.0, Genera 8 5 Joshua Metering Patches 1.0,
;;; Genera 8 5 Statice Runtime Patches 1.0, Genera 8 5 Statice Patches 1.0,
;;; Genera 8 5 Statice Server Patches 1.0,
;;; Genera 8 5 Statice Documentation Patches 1.0, Genera 8 5 Clim Patches 1.0,
;;; Genera 8 5 Genera Clim Patches 1.0, Genera 8 5 Postscript Clim Patches 1.0,
;;; Genera 8 5 Clx Clim Patches 1.0, Genera 8 5 Clim Doc Patches 1.0,
;;; Genera 8 5 Clim Demo Patches 1.0, Genera 8 5 Color Patches 1.1,
;;; Genera 8 5 Images Patches 1.0, Genera 8 5 Image Substrate Patches 1.0,
;;; Genera 8 5 Lock Simple Patches 1.0, Genera 8 5 Concordia Patches 1.0,
;;; Genera 8 5 Concordia Doc Patches 1.0, Genera 8 5 C Patches 1.0,
;;; Genera 8 5 Pascal Patches 1.0, Genera 8 5 Fortran Patches 1.0,
;;; Experimental CL-HTTP Documentation 2.0,
;;; Experimental CL-HTTP CLIM User Interface  5.0, Ivory Revision 5,
;;; VLM Debugger 329, Genera program 8.16, DEC OSF/1 V4.0 (Rev. 110),
;;; 1152x822 24-bit TRUE-COLOR X Screen RELATUS:0.0 with 224 Genera fonts (eXodusPowerPC 7.0  (c) 1998 White Pine Software,
;;; Inc. R6300), Machine serial number -2141189518,
;;; Vlm lmfs patch (from W:>Reti>vlm-lmfs-patch.lisp.12),
;;; Patch TCP hang on close when client drops connection. (from HTTP:LISPM;SERVER;TCP-PATCH-HANG-ON-CLOSE.LISP.10).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:SERVER;WEB-CONFIGURATION.LISP.41")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:SERVER;WEB-CONFIGURATION.LISP.41")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-")

;;;------------------------------------------------------------------- 
;;;
;;; CONFIGURATION FORM PROTOTYPE
;;;

;;; This form prototype specifies which preferences users are allowed to set
;;; through this interface.  also controls ordering of the layout. keywords
;;; are used to access preference objects.  set :http-port here?
(defparameter *remote-configuration-form-prototype*
              '(:listening-processes
                 :max-connections
                
                 :accept-write-methods
                 :authentication-data-pathname
                 :read-subnets
		 :write-subnets

                 :auto-export
                 :standard-export-pathnames
                
                 :mail-host
                 :bug-list
                 :maintainer
                 #+CCL-3 :network-mail-host
                 #+CCL-3 :store-and-forward-mail-hosts
                
                 #+MCL :host-name-for-apple-talk-operation
                 :resolve-ip
                 :url-host-name-resolution

                 
                 :log-resolve-ip
                 :log-times-in-gmt
                 :log-file-stream-stays-open
                 :log-directory
                 :log-class
                 :log-notifications             ;creates log objects must follow :log-class
                
                 :write-config-file
                 :config-pathname
                 ))

(fmakunbound 'http::parse-secure-subnets)
(remhash :secure-subnets http::*preference-table*)
