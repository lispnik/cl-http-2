;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: USER; Base: 10; Patch-File: t -*-
;;; Patch file for W4 version 45.1
;;; Reason: Function W4::EXECUTE-QUEUE-ENTRY:  -
;;; Written by JCMa, 7/18/00 01:33:48
;;; while running on FUJI-VLM from FUJI:/usr/lib/symbolics/ComLink-39-8-F-MIT-8-5.vlod
;;; with Open Genera 2.0, Genera 8.5, Documentation Database 440.12,
;;; Logical Pathnames Translation Files NEWEST, CLIM 72.0, Genera CLIM 72.0,
;;; PostScript CLIM 72.0, MAC 414.0, 8-5-Patches 2.17, Statice Runtime 466.1,
;;; Statice 466.0, Statice Browser 466.0, Statice Documentation 426.0, Joshua 237.4,
;;; CLIM Documentation 72.0, Showable Procedures 36.3, Binary Tree 34.0,
;;; Mailer 438.0, Working LispM Mailer 8.0, HTTP Server 70.57,
;;; W3 Presentation System 8.1, CL-HTTP Server Interface 53.0,
;;; Symbolics Common Lisp Compatibility 4.0, Comlink Packages 6.0,
;;; Comlink Utilities 10.2, COMLINK Cryptography 2.0, Routing Taxonomy 9.0,
;;; COMLINK Database 11.26, Email Servers 12.0, Comlink Customized LispM Mailer 7.1,
;;; Dynamic Forms 14.4, Communications Linker Server 39.8,
;;; Lambda Information Retrieval System 22.3, HTTP Client Substrate 3.13,
;;; HTTP Proxy Server 5.16, HTTP Client 49.8, Image Substrate 440.4,
;;; Essential Image Substrate 433.0, W4 Constraint-Guide Web Walker 45.0,
;;; W4 Examples 14.0, Jcma 42, Ivory Revision 5, VLM Debugger 329,
;;; Genera program 8.11, DEC OSF/1 V4.0 (Rev. 110),
;;; 1280x994 8-bit PSEUDO-COLOR X Screen FUJI:0.0 with 224 Genera fonts (DECWINDOWS Digital Equipment Corporation Digital UNIX V4.0 R1),
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
;;; Prevent reset of input buffer on tcp reset by HTTP servers. (from HTTP:LISPM;W4;RECEIVE-TCP-SEGMENT-PATCH.LISP.7).



(SCT:FILES-PATCHED-IN-THIS-PATCH-FILE 
  "HTTP:W4;WALKER.LISP.94")


;========================
(SCT:BEGIN-PATCH-SECTION)
(SCT:PATCH-SECTION-SOURCE-FILE "HTTP:W4;WALKER.LISP.94")
(SCT:PATCH-SECTION-ATTRIBUTES
  "-*- Syntax: Ansi-Common-Lisp; Base: 10; Mode: lisp; Package: w4; -*-")

(defun execute-queue-entry (queue-entry)
  (flet ((note-task-error (queue-entry error)
	   (let* ((url (qe-url queue-entry))
		  (activity (qe-activity queue-entry))
		  (message (format nil "~&Error Executing Task for ~A~&Error: ~S~&Report: ~A"
				   (name-string url) (type-of error) (report-string error))))
	     (record-url-note activity message :error message))))
    (let ((status :abort))
      (cond (*debug-walker*
	     (prog ()
		retry
		   (restart-case
		     (setq status (%execute-task queue-entry))
		     (retry ()
			    :report (lambda (stream)
				      (format stream "Retry W4 Task on ~A" (qe-url queue-entry)))
			    :test (lambda (condition) condition)
			    (go retry))
		     (skip ()
			   :report (lambda (stream)
				     (format stream "Skip W4 Task on ~A" (qe-url queue-entry)))
			   :test (lambda (condition) condition)
			   (return (setq status :abort))))))
	    (t (setq status (handler-case
			      (%execute-task queue-entry)
			      (network-error () :retry)
			      (condition () :retry)
			      (error (err) (note-task-error queue-entry err) :error)))))
	
      status)))

