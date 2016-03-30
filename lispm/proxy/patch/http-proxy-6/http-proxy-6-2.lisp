;;; -*- Mode: LISP; Syntax: Ansi-common-lisp; Package: HTTP; Base: 10; Patch-File: T -*-
;;; Patch file for HTTP-PROXY version 6.2
;;; Reason: Abstract out the cache instance variable and inherit into database.
;;; 
;;; CLOS class HTTP::BASIC-CACHE-MIXIN:  new mixin.
;;; CLOS class HTTP::CACHE-OBJECT:  -
;;; CLOS class HTTP::DATABASE:  -
;;; Function (CLOS:METHOD HTTP::INITIALIZE-PROXY-DATABASE (HTTP::PROXY-CACHE)):  -
;;; Function (CLOS:METHOD HTTP::INITIALIZE-PROXY-DATABASE (HTTP::FILESYSTEM-DATABASE)):  -
;;; Written by JCMa, 11/30/00 14:36:23
;;; while running on FUJI-VLM from FUJI:/usr/lib/symbolics/ComLink-39-8-F-MIT-8-5.vlod
;;; with Open Genera 2.0, Genera 8.5, Documentation Database 440.12,
;;; Logical Pathnames Translation Files NEWEST, CLIM 72.0, Genera CLIM 72.0,
;;; PostScript CLIM 72.0, MAC 414.0, 8-5-Patches 2.19, Statice Runtime 466.1,
;;; Statice 466.0, Statice Browser 466.0, Statice Documentation 426.0, Joshua 237.4,
;;; CLIM Documentation 72.0, Showable Procedures 36.3, Binary Tree 34.0,
;;; Mailer 438.0, Working LispM Mailer 8.0, HTTP Server 70.88,
;;; W3 Presentation System 8.1, CL-HTTP Server Interface 53.0,
;;; Symbolics Common Lisp Compatibility 4.0, Comlink Packages 6.0,
;;; Comlink Utilities 10.3, COMLINK Cryptography 2.0, Routing Taxonomy 9.0,
;;; COMLINK Database 11.26, Email Servers 12.0, Comlink Customized LispM Mailer 7.1,
;;; Dynamic Forms 14.4, Communications Linker Server 39.8,
;;; Lambda Information Retrieval System 22.3, Experimental Genera 8 5 Patches 1.0,
;;; Genera 8 5 System Patches 1.21, Genera 8 5 Mailer Patches 1.1,
;;; Genera 8 5 Joshua Patches 1.0, Genera 8 5 Statice Runtime Patches 1.0,
;;; Genera 8 5 Statice Patches 1.0, Genera 8 5 Statice Server Patches 1.0,
;;; Genera 8 5 Statice Documentation Patches 1.0, Genera 8 5 Clim Patches 1.0,
;;; Genera 8 5 Genera Clim Patches 1.0, Genera 8 5 Postscript Clim Patches 1.0,
;;; Genera 8 5 Clim Doc Patches 1.0, Genera 8 5 Lock Simple Patches 1.0,
;;; HTTP Proxy Server 6.1, HTTP Client Substrate 4.0, Statice Server 466.2,
;;; Ivory Revision 5, VLM Debugger 329, Genera program 8.16,
;;; DEC OSF/1 V4.0 (Rev. 110),
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
;;; Domain ad host patch (from W:>reti>domain-ad-host-patch.lisp.21),
;;; Background dns refreshing (from W:>reti>background-dns-refreshing.lisp.6),
;;; Cname level patch (from W:>reti>cname-level-patch).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:PROXY;CLASS.LISP.30"
  "HTTP:PROXY;DATABASE.LISP.77"
  "HTTP:PROXY;DATABASE.LISP.78")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:PROXY;CLASS.LISP.30")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: http; BASE: 10; Syntax: ANSI-Common-Lisp; Default-Character-Style: (:FIX :ROMAN :NORMAL);-*-")

;;;------------------------------------------------------------------- 
;;;
;;; CACHE OBJECT CLASSES
;;;

(defclass basic-cache-mixin () ((cache :initarg :cache :accessor cache-object-cache)))


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:PROXY;CLASS.LISP.30")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: http; BASE: 10; Syntax: ANSI-Common-Lisp; Default-Character-Style: (:FIX :ROMAN :NORMAL);-*-")

(defclass cache-object (basic-cache-mixin)
    ((lock :initarg :lock :accessor cache-object-lock)
     (creation-date :initarg :creation-date :accessor cache-object-creation-date :type (or null integer))	;cache creation time
     (size :initform 0 :initarg :size :accessor cache-object-size :type integer))
  (:documentation "Basic cache object."))


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:PROXY;CLASS.LISP.30")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: http; BASE: 10; Syntax: ANSI-Common-Lisp; Default-Character-Style: (:FIX :ROMAN :NORMAL);-*-")

;;;------------------------------------------------------------------- 
;;;
;;; DATABASE CLASSES
;;;

(defclass database (basic-cache-mixin)
    ((entity-handle-class :initform 'entity-handle :reader entity-handle-class :allocation :class)
     (metadata-handle-class :initform 'metadata-handle :reader metadata-handle-class :allocation :class)
     (name :initform nil :accessor database-name))
  (:documentation "A generic database."))

;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:PROXY;DATABASE.LISP.77")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-")

(defmethod initialize-proxy-database ((database filesystem-database) &aux (count 0) (orphan-count 0))
  (flet ((reload-metadata (pathname)
	   (let ((metadata-pathname (make-pathname :type *metadata-file-type* :version :newest :defaults pathname)))
	     (handler-case
	       (progn 
		 (restore-metadata database metadata-pathname *metadata-storage-mode*)
		 (incf count))
	       ;; Automatically GC orphaned entity files during proxy initialization.
	       (file-not-found ()
			       (when (equalp (pathname-type pathname) *entity-data-file-type*)
				 (incf orphan-count)
				 (delete-file pathname)))))))
    (declare (dynamic-extent #'reload-metadata))
    (let ((pathname (filesystem-database-cache-directory database))
	  (*proxy-cache* (cache-object-cache database)))	;must be bound to current cache for successful reload
      (log-event :normal "Restoring Proxy Cache from ~A...." pathname)
      (map-proxy-cache-pathnames pathname #'reload-metadata :file-type *entity-data-file-type*)
      (unless (zerop orphan-count)
	(log-event :normal "Deleted ~D orphaned entity file~:P." orphan-count))
      (log-event :normal "Restored ~D cache entr~:@P from ~A." count pathname)
      database)))


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:PROXY;DATABASE.LISP.78")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: http -*-")

(defmethod initialize-proxy-database ((cache proxy-cache))
  (let ((database (cache-database cache)))
    (clrhash (cache-resource-table cache))
    (setf (cache-object-cache database) cache) 
    (initialize-proxy-database database)))

