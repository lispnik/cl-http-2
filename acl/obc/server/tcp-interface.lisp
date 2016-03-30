;;; -*- Mode: lisp; Syntax: ansi-common-lisp; Package: http; Base: 10 -*-

;;; Copyright John C. Mallery,  1995.
;;; All rights reserved.
;;;
;;; Copyright (C) 1995, Olivier (OBC).
;;;	All Rights Reserved -- Allegro UNIX extensions.
;;;

;;;------------------------------------------------------------------- 
;;;
;;; MULTI-THREADED SERVER INTERFACE 
;;;

(in-package :http)

;;;------------------------------------------------------------------- 
;;;
;;;  STREAM AND SERVER RESOURCES
;;;

;;; This will be reset by the configuration files. Typically 5 for MCL
;;; 1-5 for ACL, 1 for Lispworks.
(defvar *number-of-listening-processes* 1
  "The number of threads simultaneously listening for HTTP connections.")

(defparameter *listener-process-priority* 0
  "The process priority of HTTP listener processes.")

(defparameter *server-run-interval* 12.
  "The interval of execution quanta allocated for each scheduling of an HTTP thread.")

;; 5 minutes in 60ths of a second.
(setq *server-timeout* (the fixnum (* 60 60 5)))

;; buffer cache in the HTTP.
(defparameter *http-stream-buffer-size* 4096 ;;  8192 , default is 1024
  "Controls the size of the HTTP stream buffer.
The default size for MACTCP is 1024, but 2048 is what Netscape uses.")

(declaim (fixnum *http-stream-buffer-size*))

(declaim (inline http-stream-connection-state))


;;;------------------------------------------------------------------- 
;;;
;;;  Resourced HTTP Processes
;;;

(defvar *process-index* 0)

(defvar *process-name-alist* nil)

;;; End CLIM-SYS bridge
;;;

(defun %register-process-name (process mac-name name)
  (clim-sys:without-scheduling
    (push `(,process ,name ,mac-name) *process-name-alist*)))

(defun %unregister-process-name (process)
  (clim-sys:without-scheduling
    (setq *process-name-alist* (delete process *process-name-alist* :key #'car)))
  process)

(declaim (inline %http-process-name))

(defun %http-process-name (process)
  (second (assoc process *process-name-alist*)))

(defun http-process-name (process)
  (or (%http-process-name process)
      (clim-sys:process-name process)))

(defun make-http-process (resource name)
  (declare (ignore resource name) (values process))
  (let* ((idx (incf *process-index*))
	 (mac-name (concatenate 'string "HTTP Process " (with-output-to-string (str)
							  (write idx :escape nil :base 10. :stream str)))))
    (clim-sys:make-process-loop :name mac-name)))

(defun initialize-http-process (#+ignore resource process name)
  (%register-process-name process (clim-sys:process-name process) name)
  process)

(defun http-process-shutdown (process)
  (when (%http-process-name process)            ; prevents multiple deallocation
    #|(notify-log-window "~&Shutdown Process ~A" process)|#
    (clim-sys:deallocate-resource 'http-process process)
    process)) 

(defun deinitialize-http-process (#+ignore resource process)
  (%unregister-process-name process)
  (clim-sys:destroy-process process)
  process)

#+CLIM-SYS ;; Using MINIPROC this would deadlock
(defun launch-process (name keywords function &rest args)
  (declare (ignore keywords))
  (clim-sys:make-process #'(lambda ()
			     (clim-sys:unwind-process (apply function args)
			       (http-process-shutdown (clim-sys:current-process))))
			 :name name))


;;;------------------------------------------------------------------- 
;;;
;;; Resourced HTTP Streams 
;;;

(declaim (inline http-stream-connection-state))

(defun http-stream-connection-state (stream)
  "Returns a Standard keyword describing the connection state of stream."
  (cond ((live-connection-p stream) :established)
	(t :closed)))

(defun tcp-connection-state (stream)
  (cond ((or (live-connection-p stream)
	     (listen stream)) 8)
	((live-connection-p stream) 0)
	(t 2)))

#+FRANZ-INC
(defclass http-stream ()
  ((host :initarg :host)
   (port :initarg :port)
   (effective-stream :initarg :stream)
   (element-type :initarg :element-type)
   (commandtimeout :initarg :commandtimeout)
   (writebufsize :initarg :writebufsize)
   (process :accessor http-stream-process)))

(defun make-http-stream (resource host &optional port timeout process)
  (declare (ignore resource host port timeout process))
  (allocate-instance (find-class 'http-stream)))

(defun initialize-http-stream (http-stream host &optional (port *STANDARD-HTTP-PORT*) (timeout *server-timeout*) (process (clim-sys:current-process)))
  (initialize-instance http-stream
                       :host host
                       :port port
                       :element-type '(unsigned-byte 8)
                       :commandtimeout timeout
                       :writebufsize *http-stream-buffer-size*)
  ;; initialize the process slot here in 3.0a but move into initialize-instance
  ;; later   2/23/95 -- JCMa.
  (setf (http-stream-process http-stream) process)
  http-stream)                                  ; return the stream

(defun deinitialize-http-stream (stream)
  (case (tcp-connection-state stream)
    (0)
    ((2) (close stream :abort t))
    (t (notify-log-window  "While deallocating a ~S, unknown tcp stream state, ~S (~D),  on ~S."
                           'http-stream
			   (http-stream-connection-state stream) 
			   (tcp-connection-state stream) stream)
       (close stream :abort t)))
  ;; deallocate process
  (shutdown-http-stream-process stream)
  (setf (http-stream-process stream) nil)
  stream)

;;; Resource arg required from server;server
#-FRANZ-INC
(defmethod deinitialize-resourced-server :before (resource (server basic-server-mixin))
  (declare (ignore resource))
  (with-slots (stream) server
    (when stream
      (clim-sys:deallocate-resource 'http-stream stream))))

;;; This can only be done after since closing the stream also kills its process
#+FRANZ-INC
(defmethod deinitialize-resourced-server :after (resource (server basic-server-mixin))
  (declare (ignore resource))
  (with-slots (stream) server
    (when stream
      (close stream :abort nil))))

(clim-sys:defresource
  http-stream (host port timeout process)
  :constructor make-http-stream
  :initializer initialize-http-stream
  :deinitializer deinitialize-http-stream
  :initial-copies 0)

(defun patch-initialize-resourced-server (server set-stream set-host set-address)
  (initialize-resourced-server 'http-server server set-stream set-host set-address))

(defun patch-deinitialize-resourced-server (server)
  (deinitialize-resourced-server 'http-server server))

(clim-sys:defresource
  http-server (stream host address)
  :constructor make-server
  :initializer patch-initialize-resourced-server
  :deinitializer patch-deinitialize-resourced-server
  :initial-copies 0)

(define http:clear-server-resource ()
  "Clears the resource of HTTP server objects."
  (clim-sys:clear-resource 'http-server))

(clim-sys:defresource
  http-process (name priority quantum)
  :constructor make-http-process
  :initializer initialize-http-process
  :deinitializer deinitialize-http-process
  :initial-copies 0)


;;;------------------------------------------------------------------- 
;;;
;;; thread mechanism 
;;;

(defmethod shutdown-http-stream-process ((tcp-stream http-stream))
  (with-slots (process) tcp-stream
    (when process
      (http-process-shutdown process))))

(defmethod enable-server ((server basic-server-mixin)) 
  (with-slots (stream) server
    (with-slots (process) stream
      (when (and stream process)
        (clim-sys:enable-process process)))))

(defmethod disable-server ((server basic-server-mixin))
  (with-slots (stream) server
    (with-slots (process) stream
      (when (and stream process)
        (clim-sys:disable-process process)))))

;;;------------------------------------------------------------------- 
;;;
;;; LISTENING STREAMS
;;;

(defvar *server-control-alist* nil
  "A property list of  streams awaiting incoming http connections on each port.")

(defun %register-listening-stream (stream &optional  (port (www-utils::foreign-port stream)))
  (clim-sys:without-scheduling
    (let ((entry (assoc port *server-control-alist* :test #'eql)))
      (cond (entry (push stream (cdr entry)))
            (t (push `(,port ,stream) *server-control-alist*))))))

(defun %swap-listening-stream (new-stream old-stream 
                                          &optional (port (www-utils:foreign-port old-stream)))
  (clim-sys:without-scheduling
    (let ((entry (assoc port *server-control-alist* :test #'eql)))
      (cond (entry
             (loop for l = entry then (cdr l)
                   while l
                   when (eq (second l) old-stream)
                     do (setf (second l) new-stream)
                        (return-from %swap-listening-stream entry)
                   finally (push new-stream (cdr entry))))
            (t (push `(,port ,new-stream) *server-control-alist*))))))

(defun %unregister-listening-stream (stream)
  (declare (values unregistered-p))
  (flet ((delete-from-entry (s entry)
           (when (member s (cdr entry) :test #'eq)
             (clim-sys:without-scheduling
               (if (cddr entry)
                   (setf (cdr entry) (delete s (cdr entry) :test #'eq))
                   (setq *server-control-alist* (delete entry *server-control-alist* :test #'eq))))
             t)))
    (let  ((port (www-utils:foreign-port stream)))
      (cond (port
             (let ((entry (assoc port *server-control-alist* :test #'eql)))
               (delete-from-entry stream entry)))
            ;; port may be null when the stream is closed, so search for it.
            (t (loop for entry in *server-control-alist*
                     when (delete-from-entry stream entry)
                       do (return t)
                     finally (return nil)))))))

(declaim (inline %listening-streams))

(define %listening-streams (&optional (port (round *STANDARD-HTTP-PORT*)))
  "Returns the streams listening on PORT."
  (cdr (assoc port *server-control-alist* :test #'eql)))

(define %map-listening-streams (function &optional (ports :all))
  "Maps FUNCTION over streams listening on PORTS,
which is either :ALL or a list of port numbers."
  (loop for (port . streams) in *server-control-alist*
        do (when (and streams 
                      (or (eq ports :all) (member port ports :test #'eql))) 
             (mapc function streams))))

(declaim (inline %listening-on-port-p))

(define %listening-on-port-p (&optional (port (round *STANDARD-HTTP-PORT*)))
  "Returns non-null when listening for HTTP connections on PORT."
  (%listening-streams port))

(declaim (inline %listening-on-ports))

(define %listening-on-ports ()
  "Returns the port numbers on which there is listening for HTTP connections."
  (mapcar #'car *server-control-alist*))

(defun %shutdown-idle-listening-stream (stream)
  (declare (values shutdown-p))
  ;; shut down only when idle
  (clim-sys:without-scheduling                       ; keep this atomic
    (let ((state (http-stream-connection-state stream)))
      (case state
        ;; already running, so let it complete.
        (:established nil)
        ;; shut it down and deallocate.
        (t ;; unregister it
          (%unregister-listening-stream stream)
          (unless (member state '(:closed))
            (close stream :abort t))
          (clim-sys:deallocate-resource 'http-stream stream)
          t)))))

;; Calling this function within a stream thread requires issuing a
;; process-run-function 2/23/95 -- JCMa.
(defun %stop-listening-for-connections (&optional (port *STANDARD-HTTP-PORT*) &aux more-streams-p)
  (flet ((careful-shutdown (stream)
           (unless (%shutdown-idle-listening-stream stream)
             (setq more-streams-p t))))
    (when (%listening-on-port-p port)
      (let ((ports (list port)))
        (declare (dynamic-extent ports))
        (loop doing 
          (%map-listening-streams #'careful-shutdown ports)
          (if more-streams-p
              (setq more-streams-p nil)
              (return)))
        ;; Advise the user. 
        (expose-log-window)
        (notify-log-window "HTTP service disabled for: http://~A:~D/"
                           (www-utils:local-host-domain-name) port)))
    (values t)))

(defun %enforce-number-of-listeners-for-connection (number &optional (port *STANDARD-HTTP-PORT*) 
                                                           (timeout *server-timeout*))
  (let* ((s (%listening-streams port))
         (len (length s)))
    (cond ((> len number)
           (loop with idx = (- number len)
                 for streams = s then (%listening-streams port)
                 do (loop for stream in streams
                          when  (%shutdown-idle-listening-stream stream)
                            do (when (zerop (decf idx))
                                 (return-from %enforce-number-of-listeners-for-connection number)))))
          ((< 0 len number)
           (dotimes (idx (- number len))
             (%start-listening-for-connections port timeout))))
    number))

#+FRANZ-INC
(defvar *acl-tcp-servers* nil)

(defmacro with-stream-fd-watcher ((stream) . body)
  #+(and Allegro (version>= 4 3))
  `(let ((#1=#:listen-socket-fd (slot-value ,stream #-(version>= 6 0) 'excl::fn-in #+(version>= 6 0) 'excl::input-handle)))
     (mp:waiting-for-input-available (#1#) ,@body))
  #-(and Allegro (version>= 4 3))
  `(progn ,stream ,@body))

#+(and Allegro (not ACL5))
(defun %listen-for-connections (port timeout)
  (declare (ignore timeout))
  (let ((stream (getf *acl-tcp-servers* port)))
    ;; Proper way to tell the scheduler where input is expected?
    ;; Trying to prevent random blocking - OBC
    (unwind-protect  #+(version>= 4 3)
		     (let ((listen-socket-fd (slot-value stream 'excl::fn-in)))
		       (mp:waiting-for-input-available (listen-socket-fd)
			 (loop
			   (clim-sys:process-wait "Wait for new connection" #'stream:stream-listen stream)
			   (listen-for-connection stream port))))
		     #-(version>= 4 3)
		     (let ((streams (list stream)))
		       (loop
			 (mp:wait-for-input-available streams :whostate "Wait for new connection")
			 (listen-for-connection stream port)))
		     (close stream))))

#+ACLPC
(defun %listen-for-connections (port timeout)
  (declare (ignore timeout))
  (let ((stream (getf *acl-tcp-servers* port)))
    (clim-sys:unwind-process
     (clim-sys:process-loop :do (when (listen stream)
				  (listen-for-connection stream port)))
     (close stream))))

#+ACL5 ;; for now, this does not call any listen-for-connection
(defun %listen-for-connections (port timeout)
   (declare (ignore timeout))
   (flet ((accept-connection-p ()
            (< *number-of-connections* *reject-connection-threshold*))
          (reject-connection (stream string)
            (when string
               (write-string string stream)
               (force-output stream))
            (close stream :abort t))
          (process-namestring (client-domain-name port)
            (concatenate 'string "HTTP Server [" (write-to-string port :base 10.)
              "] (" client-domain-name ")")))
     (declare (inline accept-connection-p reject-connection process-namestring))
     (let ((non-stream (getf *acl-tcp-servers* port))
           stream)
        (unwind-protect
             (loop
               (setq stream (ipc::stream-read non-stream))
               #+Debug (pushnew stream *acl-listens*) ;Debugging only
               (case (tcp-connection-state stream)
                 (8 ;; :established
                  (cond ((accept-connection-p)
                         (let* ((client-address (www-utils::foreign-host stream))
                                (client-domain-name (host-domain-name client-address)))
                            ;; set the timeout to the connected value
                            #+Debug
                            (format *trace-output* "~&Launching new HTTP listener...~%")
                            ;; start a thread to provide http service
                            (launch-process (process-namestring client-domain-name port)
                             '(:priority 0)
                             '%provide-service stream client-domain-name client-address)
                            :new-stream))               ; request new listening stream
                        (t (reject-connection stream *reject-connection-message*)
                          :block)))                   ; Continue running 
                 (t #+FRANZ-INC
                   (if stream (close stream :abort t))
                   :continue)))
           (close non-stream))
        )
     )
   )

#+FRANZ-INC
(defvar *standard-port-range* 0)

(defpackage "HTTP" (:use) (:export "STANDARD-PORT-RANGE"))

#+FRANZ-INC
(defun standard-port-range (&optional val)
  (if (integerp val)
      (setq *standard-port-range* val)
    *standard-port-range*))

#+FRANZ-INC
(defun enable-http-stream-server (port &key (new-location t))
  (declare (special http::*http-ports*))
  (let (stream (trueport port))
    (www-utils::default-domain-name)
    (let (standard-port-change 
	  ;; bind80 case
	  (listen-fd (get-line-argument "listen_fd=" 'fixnum))
	  (host (get-line-argument "host=" 'string))
	  (hiper (get-line-argument "hiper=" 'symbol))
	  (newport (get-line-argument "port=" 'fixnum)))
      (if listen-fd
	  (unless (eql newport 80)
	    (warn "Assuming port argument value port=80")
	    (setq newport 80)))
      (if host
	  (install-symbolic-host-shadow host :port (or newport port)
					:update-context-p nil
					:reset-port-p nil))
      ;; Now avoid (open "" :class ...) bug 3/95
      (unless newport (setq newport port))
      (unless (setq stream (getf *acl-tcp-servers* newport))
	(clim-sys:without-scheduling
	  #+ACLPC
	  (setq stream (socket:make-socket :connect :passive :local-port port))
	  #+(and Allegro (not ACL5))
	  (setq stream (make-instance 'ipc:tcp-server-stream
			 :host (www-utils::%local-host-name)
			 :port newport
			 :listen-fd listen-fd
			 :tcp-port-max (+ port (standard-port-range))))
	  #+ACL5
	  (setq stream (change-class
			#-(version>= 6)
                        (socket:make-socket :connect :passive :local-port port :reuse-address t :format :bivalent)
			#+(version>= 6)
                        (apply #'socket:make-socket :connect :passive :local-port port :reuse-address t :format :bivalent (and hiper (list :type :hiper)))
                        'ipc:tcp-server-stream))
	  (setq trueport (local-port stream))
	  (setf (getf *acl-tcp-servers* trueport) stream)))
	(unless (eql trueport port)
	  (warn "Using substitute port ~a instead of port ~a." trueport port)
	  (when (eql port *standard-http-port*)
	    (setq standard-port-change trueport)))
	(www-utils::reset-http-server-location :standard-port-change standard-port-change
					       :reset-location new-location)
	trueport)))

;; make sure server on this port
(defun ensure-http-protocol-on-port (port)
  (getf *acl-tcp-servers* port))

#+FRANZ-INC
(defvar *acl-http-processes* nil)

(defun %start-listening-for-connections (&optional (port *STANDARD-HTTP-PORT*) (timeout *server-timeout*)
                                                   (process-priority *listener-process-priority*))
  "Primitive to begin listening for HTTP connections on PORT with server timeout, TIMEOUT."
  ;; run the listening thread
  (flet ((process-namestring ()
           (concatenate 'string "HTTP Listen [" (write-to-string port :base 10.) "]")))
    (declare (inline process-namestring))
    (let ((keywords `(:priority ,process-priority))
	  process)
      (declare (dynamic-extent keywords))
      (setq process (launch-process (process-namestring) keywords #'%listen-for-connections port timeout))
      #+FRANZ-INC
      (push process *acl-http-processes*))))

;;; Originally stream was not be closing on failure cases? OBC.
;;;
(defun %provide-service (stream client-domain-name client-address)
  (%provide-service-internal stream client-domain-name client-address))

(defun %provide-service-internal (stream client-domain-name client-address)
  (flet ((log-dropped-connection (server)
	   (www-utils::abort-http-stream stream)
           (set-server-status server 408)       ;client timeout status code changed from 504 -- JCMa 5/29/1995.
           (log-access server)
	   #+FRANZ-INC
	   (close stream :abort t))
         (handle-unhandled-error (server error)
	   (handler-case
             (progn
               (set-server-status server 500)
               (log-access server)
               (report-status-unhandled-error error stream (server-request server))
               (close stream :abort nil))	; force output
	     (network-error (e)
			    (declare (ignorable e))
			    #+FRANZ-INC (close stream :abort t))
	     #+Allegro
	     (file-error (error)
			 (or #-ACL5 (ipc::handle-open-file-error error)
			     (www-utils:report-condition error t))
			 (close stream :abort t))
	     ;; Any other error we did not anticipate?
	     (error (error)
			  (warn "Ignoring the following error.")
			  (www-utils:report-condition error t)
			  #+FRANZ-INC (close stream :abort nil)))
           ;; log the access after the output has been forced.
           (log-access server)))
    ;; make sure we know our process.
    #+(Allegro (and not acl5))
    (setf (ipc::tcp-stream-process stream) (clim-sys:current-process))
    #-FRANZ-INC
    (setf (http-stream-process stream) (clim-sys:current-process))
    (clim-sys:using-resource
     ;; Notice the resource name HTTP-SERVER is NOT quoted
      (server http-server stream client-domain-name client-address)
      (let ((*server* server)) 
        (with-stream-fd-watcher (stream)
	  (handler-case-if
	   (not *debug-server*)
	   (progn 
	     (www-utils:with-optimal-stream-buffer ()
	       (provide-service server))
	     #+Allegro
	     (close stream :abort nil))
	   ;; catch aborts anywhere within server.-- JCMa 12/30/1994.
	   (http-abort (e) 
		       (declare (ignorable e))
		       (www-utils::abort-http-stream stream))
	   (protocol-timeout (e) 
			     (declare (ignorable e))
			     (log-dropped-connection server))
	   (connection-lost (e) 
			    (declare (ignorable e))
			    (log-dropped-connection server))
	   (host-stopped-responding () 
				       (log-dropped-connection server))
	   (bad-connection-state (e) 
				 (declare (ignorable e))
				 (log-dropped-connection server))
	   (file-error (error)
		       (declare (ignorable error))
		       (log-dropped-connection server))
	   (error (error) 
			  (handle-unhandled-error server error))))))))

#+FRANZ-INC
(defvar *acl-listens* nil)

#-ACL5
(define listen-for-connection (stream port)
  (declare (values control-keyword))
  (flet ((accept-connection-p ()
           (< *number-of-connections* *reject-connection-threshold*))
         (reject-connection (stream string)
           (when string
             (write-string string stream)
             (force-output stream))
           (close stream :abort t))
         (process-namestring (client-domain-name port)
           (concatenate 'string "HTTP Server [" (write-to-string port :base 10.)
                        "] (" client-domain-name ")")))
    (declare (inline accept-connection-p reject-connection process-namestring))
    (cond ((listen stream)
	   #+FRANZ-INC	 ;Get new connection stream
	   (www-utils:with-optimal-stream-buffer ()
	     (setq stream (handler-case (clim-sys:without-scheduling
					  (ipc:stream-read stream))
			    (local-network-error ()
			      (return-from listen-for-connection :continue)))))
	   #+(and FRANZ-INC Debug)
	   (pushnew stream *acl-listens*) ;Debugging only
	   (case (tcp-connection-state stream)
	     (8 ;; :established
	      (cond ((accept-connection-p)
		     (let* ((client-address (www-utils::foreign-host stream))
			    (client-domain-name (host-domain-name client-address)))
		       ;; set the timeout to the connected value
		       #+Debug
		       (format *trace-output* "~&Launching new HTTP listener...~%")
		       ;; start a thread to provide http service
		       (launch-process (process-namestring client-domain-name port)
				       '(:priority 0)
				       #'%provide-service stream client-domain-name client-address)
		       :new-stream))               ; request new listening stream
		    (t (reject-connection stream *reject-connection-message*)
		       :block)))                   ; Continue running 
	     (t #+FRANZ-INC
		(if stream (close stream :abort t))
		:continue)))
	  ((%listening-on-port-p port) :block)
	  (t :quit))))

;;;------------------------------------------------------------------- 
;;;
;;; HIGH LEVEL OPERATIONS TO CONTROL HTTP SERVICE 
;;;

(eval-when (eval load)
(defparameter *http-ports* (list *STANDARD-HTTP-PORT*)
  "The ports over which http service is provided.")
)

(define enable-http-service (&key (on-ports *http-ports*) (new-location t) (listeners *number-of-listening-processes*) (start (get-line-argument "start=" 'symbol)))
  "Top-level method for starting up HTTP servers."
  (setq on-ports (ensure-list on-ports))
  ;; Shutdown any listeners that may be awake.
  (disable-http-service on-ports)
  ;; before starting a new batch
  (dolist (port (setq *http-ports* on-ports))
    ;; Provide multiple listening streams so that MACTCP is ready to accept the connection.
    #+FRANZ-INC ;; Prepare server streams
    (setq port (enable-http-stream-server port :new-location new-location))
    (when start
      (dotimes (idx (ceiling listeners (length on-ports)))
	       (%start-listening-for-connections port 0))
      ;; Advise the user.
      (expose-log-window)
      (notify-log-window "HTTP service enabled for: http://~A:~D/~%"
			 (www-utils:local-host-domain-name) port))
    on-ports))

(defpackage "HTTP"
  (:use) (:export "START" "EXIT"))

(defvar *resync-4-3-logical-host* t)

(defvar *fast-remap-p* nil
  "Set this to get quick and partial remap upon server restart.
Only supports http urls but is faster than the full remap.")

(define start (&key (log (get-line-argument "log=" 'symbol))
		    (update (get-line-argument "update=" 'symbol))
		    (evaluate (get-line-argument "eval=" 'list))
		    (shadow (get-line-argument "shadow=" 'string))
		    (new-location t)
		    (fast-remap-p (get-line-argument "fastremap=" 'symbol))
		    (listeners *number-of-listening-processes*)
		    (port (or (get-line-argument "port=" 'fixnum) 80))
		    (host (get-line-argument "host=" 'string))
		     ; the root directory for cl-http
		    (home (get-line-argument "home=" 'string))
		    (proxy (get-line-argument "proxy=" 'symbol))
		    (start t))
  "Short version of ENABLE-HTTP-SERVICE."
  ;;; Get this from the start.lisp file for now 4.3 looses the logical hosts!
  (if home
      (setq user::*http-directory* (pathname home)))
  
  (www-utils::load-logical-host-translations
   "http"
   :location user::*http-directory*
   :defaults (merge-pathnames www-utils::*http-image-place* user::*http-directory*))

  ;; Still cannot get a readtable saved with fasl images
  ;; add this first so we can load new examples below
  (set-dispatch-macro-character #\# #\u  #'sharp-sign-u-reader-helper)

  (when update
    (user::load-system "cl-http"))

  ;; remember the number of the listeners for a server restart
  (setq *number-of-listening-processes* listeners)
  
  ;; we are shadowing that name anyway, it may not be real
  (unless shadow
    (ipc:compute-host-domain-name (or host http:*http-host-name*)))
  
  ;; Doing this now would prevent url remapping!!
  ;;(reset-server-local-host-variables :standard-port port)
  
  ;; upon a restart we want to be sure that the toplevel that comes up
  ;; doesn't replace the readtable with the #u macro defined with
  ;; a fresh readtable.  This will prevent that.
  (setq excl::*cl-default-special-bindings*
	(delete '*readtable* excl::*cl-default-special-bindings* :key #'car))

  (when start
    (run-server-initializations t)
    (run-server-launch-initializations t)

    (setq *fast-remap-p* fast-remap-p)

    (enable-http-service :on-ports (list port) :listeners listeners :new-location new-location :start start)

    (if shadow
	(install-symbolic-host-shadow shadow))
    (if (consp evaluate)
	(clim-sys:make-process #'(lambda ()
				   (clim-sys:process-sleep 5)
				   (eval evaluate))
			       :name "CL-HTTP Initialization Evaler"))
    (www-utils::periodic-tasks)

    (http::start-connection-scavenger)
    (http:log-notifications-on (http:current-access-logs) log)
    (if log
	(format t "~&CL-HTTP serving at ~a - With log.~%" http::*http-ports*)
      (format t "~&CL-HTTP serving at ~a - NO log.~%" http::*http-ports*))
    ;; ACL startup print fix
    (terpri))
  
  (when proxy
    ;; persistent connections cause problems when accessing www.cnn.com
    ;; with the proxy server on.
    (setq http::*client-persistent-connections* nil)
    (enable-proxy-service)))
		     
(defun exit (&optional (all-the-way t))
  (disable-http-service)
  (http::stop-connection-scavenger)
  (www-utils::periodic-tasks :exit t)
  (and all-the-way #+Allegro (excl:exit) #+ACLPC (sys:system-quit nil nil nil)))

#+FRANZ-INC
(defun disable-http-service (&optional ignore)
  (declare (ignore ignore))
  (close-all-logs)
  ;; Plist
  (mapc #'(lambda (x)
	    (if (streamp x)
		(close x :abort nil)))
	*acl-tcp-servers*)
  (mapc #'(lambda (x)
	    (clim-sys:destroy-process x))
	*acl-http-processes*)
  (setq *acl-tcp-servers* nil *acl-http-processes* nil))

(defmethod shutdown-server ((server basic-server-mixin))
  "Forcibly shutdown a running (or idle) HTTP server."
  (with-slots (stream) server
    (when stream
      (close stream :abort t))
    (clim-sys:deallocate-resource 'http-server server)))

;;; I think function as first argument makes more
;;; sense for all MAP type functions.
;;; Notice CLIM-SYS:MAP-RESOURCE args.
;;;
(define map-http-resource (keyword allocation function)
  "Maps FUNCTION over the resource denoted by KEYWORD with ALLOCATION. 
KEYWORD can be any of :STREAM, :SERVER, or :PROCESS
ALLOCATION can be any of :ALL, :FREE, or :ALLOCATED."
  (flet ((fctn (item allocated-p resource)
           (declare (ignore resource))
           (when (ecase allocation
                   (:all t)
                   (:free (not allocated-p))
                   (:allocated allocated-p))
             (funcall function item))))
    (clim-sys:map-resource #'fctn
		  (ecase keyword
		    (:stream 'http-stream)
		    (:server 'http-server)
		    (:process 'http-process)))))

(define all-servers (&aux servers)
  (flet ((collect (server)
           (push server servers)))
    (map-http-resource :server :allocated #'collect)
    servers))

(define %clear-http-process-resource ()
  "Deallocates all resourced HTTP processes."
  (map-http-resource :process :free #'clim-sys:destroy-process)
  (clim-sys:clear-resource 'http-process))

(define shutdown-http-service ()
  "Forcibly shutdown all HTTP servers."
  (prog1 (disable-http-service :all)
         (map-http-resource :server :allocated #'shutdown-server)
         (close-all-logs)))

(define stop ()
  (disable-http-service))

;;; Special ACLPC pathname translation required
;;;

#+ACLPC
(user::handling-redefinition
(defmethod translated-pathname ((pathname string))
  #-ACLPC
  (translated-pathname (pathname pathname))
  #+ACLPC
  (translate-logical-pathname pathname))
)

#+ACLPC
(user::handling-redefinition
(defmethod translated-pathname ((pathname pathname))
  #-ACLPC
  pathname
  #+ACLPC
  (translate-logical-pathname pathname))
)

; 
; the acl version of a function  in server/utils.lisp

(defmethod http-input-data-available-p ((stream ipc:tcp-client-stream) 
				      &optional timeout-seconds)
  ;; return true if there is non-whitespace data available
  ;; If timeout is given then don't wait any longer than that
  ;; for the answer

  (flet ((data-available-p (stream)
	   ;; see if there is non-whitespace data readable.
	   ;; return t if so.
	   ;; skip all whitespace characters.
	   ;; block on the first read but not subsequent ones
	   (let ((ch (peek-char nil stream nil)))
	     (loop
	       (if (null ch)
		   (return nil) ; eof
		 (if (not (member ch
				  '(#\return #\linefeed #\space #\tab)
				  :test #'eq))
		     (return t) ; have a character
		   (progn (read-char stream)
			  (if (not (listen stream))
			      (return nil) ; no more now available
			    (setq ch (peek-char nil stream nil))))))))))
    
		       
    (if (not (www-utils:live-connection-p stream))
        nil  ; dead connection, no data
     (if timeout-seconds
	 (mp:with-timeout (timeout-seconds 
			   (and (listen stream)
				(data-available-p stream)))
			  (loop (if (data-available-p stream)
				    (return t))))
       (and (listen stream)
	    (data-available-p stream))))))

;; imported from jkf/server/tcp
;; temporary defined to get around acl 6.0 problem with
;; effective methods with eql specializers [bug10451]
#+(version>= 6)
(defmethod add-access-log (log port) nil)

    
