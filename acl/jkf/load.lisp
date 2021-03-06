;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package: cl-user; Base: 10 -*-
;;
;;

;; this file controls the building of cl-http 
;;
;; see readme-acl.txt for details on how to build cl-http.
;;
;; The version number is in version.lisp
;;

(in-package :cl-user)

(defpackage :http)  

;;; KAP 2003-05-03
;;; Only change mode if needed
(unless (eq *CURRENT-CASE-MODE* :case-insensitive-upper)
  (set-case-mode :case-insensitive-upper)) 

(pushnew :multi-threaded *features*) ; need before compiling the code
(pushnew :http-chunking *features*)
(pushnew :ANSI-documentation *features*)

(setq excl:*record-source-file-info* t) ; helps debugging
(setq excl:*load-source-file-info* t) ; helps debugging

(load (make-pathname :name "translations" :type "lisp" :defaults *load-pathname*))

;;; KAP 2003-05-03
;;; Compile the export files

(defun compile-files (filelist &key force-compile)
  (with-compilation-unit ()
    (dolist (file (compute-filelist filelist))
      (if* force-compile
         then (compile-file file)
         else (compile-file-if-needed file))
      )
    )
  )

;;; Surprisingly you have to at least configure the server before being able to compile some example files
(defun compile-exports (&key force-compile)
  (compile-files
   '(
     
     "http:examples;documentation.lisp"
     "http:examples;access-control.lisp"
     "http:w3p;documentation.lisp"
     "http:examples;log-window.lisp"
     "http:examples;vrml;vrml.lisp"
     "http:examples;twistdown-tree;twistdown.lisp"
     "http:examples;lispdoc.lisp"
     "http:examples;examples.lisp"
     "http:examples;find-url.lisp"
     #+no "http:examples;client.lisp" ;exports directly
     #+no "http:examples;mcf095;mcf.lisp"
     #+no "http:acl;obc;examples;exports.lisp"
     #+no "http:acl;jkf;examples;exports.lisp"
     #+no "http:lw;examples;exports.lisp"
     #+no "http:lcl;examples;exports.lisp"
     #+no "http:cmucl;examples;exports.lisp"
     
     ;partially loads some of the files
     "http:w4;examples;trace.lisp"
     "http:w4;examples;search"
     "http:w4;examples;web-archive"
     #+no "http:w4;examples;exports"
     )
   :force-compile force-compile
   )
  )

; this is a portable defsystem and multiprocessing pacakge
;* we aren't using the defsystem part here so we don't need it ourselves
;  but maybe people using cl-http need it.
(defparameter *files-clim-sys*
  '(("http:clim;clim-sys;" "package" "process" "miniproc" "resources" "resource" "util" "demo")))

(defparameter *files-w3p*
  '(("http:w3p;"
     "package"
     "class"
     "w3p-system"
     "functions"
     "standard-types"
     "standard-methods"
     "html-definitions")))

(defparameter *files-cl-http*
  `(("http:server;" "package" "preliminary" "variables")
    "http:port;version"
    "http:port;ipc"
    "http:port;server;tcp-stream"
    "http:mcl;server;resources"
    "http:port;server;unix"
    "http:mcl;server;www-utils"
    ;;; KAP define the missing utils
    "http:port;patches;missing-www-utils"
    ("http:server;" "base64-encoding" "md5" "sha" "task-queue")
    ("http:smtp;"   "package" "smtp" "mail")
    ("http:server;"
     "class"			; Server class definitions
     "url-class"		; URL class definitions 
     "http-conditions" 
     "plist"			; property list mixin for CLOS
     "utils"			; utility functions
     "tokenizer"		; Simple tokenizer
     "headers"                ; Header hacking, including MIME
     "host"                   ; Host objects and operations
     "url"                    ; URL implementation
     "html2"                  ; HTML authoring functions
     "netscape-1-1"		; Netscape 1.1 html generation
     "vrml-1-0"		; HTML 1.0 Generation
     "image-maps"		; Image maps
     "netscape-2-0"		; Netscape 2.0 HTML generation
     "netscape-3-0"		; Netscape 3.0 HTML generation
     "html-3-2"		; HTML 3.2 Generation	
     "html4"			; HTML 4 Generation	
     "scripts"	        	; Client-Side Scripts
     "netscape-4-0"		;  Netscape 4.0 HTML generation
     "shtml")			; Server-side includes
    ,@*files-w3p*		;insert W3P 
    ("http:server;"
     "report"			; Reporting for HTTP Conditions
     "log"                    ; Logging 
     "authentication"		; User authentication
     "data-cache"		; Data caching
     "server"                 ; HTTP Server
     "cgi"			; Common Gateway Interface
     "preferences"
     "web-configuration")
    ("http:port;server;"
     "url"
     "update"
     "cgi"
     ;"proxy"
     "tcp"
     "patched"
     "pathname-get-value"
     )
    ;;;;kap patches
    ("http:port;patches;"
     "missing-url"
     "missing-user"
     "missing-http"
     "patch-directory-list"
     "patch-disable-http-service"
     "patch-local-context"
     "patch-http-log"
     "patch-ipc"
     "patch-notification-log"
     "console-log"
     "hiper-sockets"
     )))

(defparameter *files-http-client-substrate*
  '("http:port;client;unix"
    ("http:client;"
     "variables"			;variables controlling the client
     "connection"			;symbols
     "proxy"			; Upstream Proxies
     "authentication"		; Client authentication
     "client")			; WWW Client substrate
    ))

(defparameter *files-http-base-client*
  ;; above and beyond substrate
  '("http:client;sexp-browser"))

(defparameter *files-http-proxy*
  ;; loaded after cl-http and http-client-substrate
  '(("http:proxy;"
     "uid"
     "package"
     "variables"
     "class"
     "utils"
     "database"
     "cache"
     "resource"
     "representation"
     "proxy-cache"
     "proxy"
     "documentation")))

(defparameter *files-w4*
  '("http:client;w4-client"
    ("http:w4;"
     "package"			; Package Definition
     "variables"                  ; Variables
     "utils"				; Utility functions and macros
     "class"				; Class definitions and Print methods
     "walker"				; Main Walker code
     "constraints"                ; Constraint Definitions
     "actions"			; Action definitions
     "activity"                   ; Activity definitionse
     )))

(defparameter *files-lambda-ir*
  '(("http:lambda-ir;" 
     "package" 
     "ir-utils"
     "variables"
     "class"
     "bit-vectors"
     "data-structures"
     "computations"
     "ir-base"
     "contexts"
     "constraints"
     "bin-dump-utils")))

(defparameter *files-w4-examples*
  '(("http:w4;examples;"
     "trace"
     "search"
     "web-archive"
     "exports")))

(defvar .files-loaded.) 

;; options
;;  [default] compile-and-load  
;;		ensure that all files are compiled, load them into lisp.
;;	      force-compile  (key  :force-compile t)
;;		compile all files even if they appear to be up to date
;;	      create-fasl    (key  :create-fasl "filename")
;;	        create cl-http.fasl from the compiled files after doing
;;		the compile-and-load
;;		
(defun build-cl-http (&key force-compile create-fasl 
                           (proxy t)
                           (w3p t)
                           (w4  t) 
                           (lambda-ir nil)
                           )
  
  
  (let ((.files-loaded.))
    (if* w3p
       then (pushnew :w3p *features*))
    
    ;;; KAP 2003-05-03
    (with-compilation-unit ()
      (compile-and-load-files *files-clim-sys* :force force-compile)
      (compile-and-load-files *files-cl-http*  :force force-compile)
      (compile-and-load-files *files-http-client-substrate*  
                              :force force-compile)
      
      (if* proxy
         then (compile-and-load-files *files-http-proxy* 
                                      :force force-compile))
      
      (compile-and-load-files *files-http-base-client*  :force force-compile)
      
      
      (if* w4
         then (compile-and-load-files *files-w4*  :force force-compile))
      (when lambda-ir
        (compile-and-load-files *files-lambda-ir*))
      ) 
    
    
    
    (if* create-fasl
       then (if* (symbolp create-fasl)
                    ;;;KAP take care that the fasl is created in the right place
               then (setq create-fasl "http:port;cl-http.fasl"))
            (format t "writing combined fasl: ~s~%" create-fasl)
            (copy-files-to (nreverse .files-loaded.) create-fasl))))

(defun compile-and-load-files (filelist &key force)
  (dolist (file (compute-filelist filelist))
    (if* force
       then (compile-file file)
       else (compile-file-if-needed file))
    (load file)
    (push file .files-loaded.)
    )
  )

(defun compute-filelist (filelist)
  ;; the filelist is a list of filespecs which are
  ;;	strings  (denoting a file)
  ;;    (dirname filespec ...) denoting files rooted at dirname
  ;;    (function ....)        denotes form to eval
  ;; return the filenames with diretories merged in
  (let (res)
    (dolist (file filelist)
      (if* (atom file) 
         then (push file res)
         else (let ((dirname (car file)))
                (if* (symbolp dirname)
                   then ; doing an eval
                        (dolist (file (eval file))
                          (push file res))
                   else (dolist (file (compute-filelist (cdr file)))
                          (push (concatenate 'string dirname file) res))))))
    (nreverse res)))

(defun copy-files-to (files dest)
  ;; copy the contents of all files to the file named dest.
  ;; append .fasl to the filenames
  
  (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8))))
    (with-open-file (p dest :direction :output
                       :if-exists :supersede
                       :element-type '(unsigned-byte 8))
      (dolist (file files)
        (with-open-file (in (concatenate 'string file  ".fasl")
                            :element-type '(unsigned-byte 8))
          (loop
            (let ((count (read-sequence buffer in)))
              (if* (<= count 0) then (return))
              (write-sequence buffer p :end count))))))))

(defun load-test (&key (w4-examples t)
                       (force-compile nil))
  ;; load files to test cl-http.
  ;; the server must be running before these files are loaded
  ;;
  (let ((.files-loaded.))
    ;;; KAP 2003-05-03
    ;;; Don't load the the .lisp files if .fasl are available
    
    ;;;JCMA forgot this
    (load "http:examples;find-url" :verbose t)
    (load "http:examples;exports")
    
    (if* w4-examples
       then (compile-and-load-files *files-w4-examples* 
                                    :force force-compile))))

; the following function is an example of a function that will
; build a standalone cl-http web server.
; In this example we load the whole lisp environment (compiler
; and debugger and fancy toplevel). In a real world situation
; we would not need that.
;
(defun makeapp ()
  ;; build a standalone lisp image containing cl-http
  ;;
  #+unix (run-shell-command "rm -fr cl-http-app")
  (generate-application 
   "cl-http"
   "cl-http-app;"
   '(:sock :process :defftype :foreign :ffcompat "cl-http.fasl")
   ; use find-symbol since http packge isn't around yet:
   :restart-init-function 'http::start
   :read-init-files t
   :print-startup-message t
   :purify nil
   :include-compiler t
   :include-devel-env t
   :include-debugger t
   :include-tpl t
   :include-ide nil
   :discard-arglists nil
   :discard-local-name-info nil
   :discard-source-file-info nil
   :discard-xref-info nil
   
   :ignore-command-line-arguments t
   :suppress-allegro-cl-banner nil))
