;;;-*- Syntax: Ansi-common-lisp; Base: 10; Mode: lisp; Package: cl-user -*-

;;; LispWorks definition for IPC and WWW-UTILS packages
;;;
;;; Copyright (C) 1996-2000 Xanalys Inc.  All rights reserved.
;;;
;;; Enhancements Copyright (c) 2005-2006, John C. Mallery. All rights reserved.
;;;

(defpackage "IPC"
  #+CL-HTTP-SSL
  (:import-from "COMM"
   "SSL-CLOSED"
   "SSL-CONDITION"
   "SSL-ERROR"
   "SSL-FAILURE")
  (:export
   ;; Condition classes
   "DOMAIN-RESOLVER-ERROR"
   "IPC-NETWORK-ERROR"
   "UNKNOWN-ADDRESS"
   "UNKNOWN-HOST-NAME"
   #+CL-HTTP-SSL "SSL-CLOSED"
   #+CL-HTTP-SSL "SSL-ERROR"
   #+CL-HTTP-SSL "SSL-FAILURE"
   ;; Functions
   "%LISTEN-FOR-CONNECTIONS"
   #+CL-HTTP-SSL
   "%LISTEN-FOR-SSL-CONNECTIONS"
   "%STREAM-COPY-BYTES"
   "ADD-CL-HTTP-STREAM-INFO"
   "FIND-DETAIL-FROM-STREAM"
   "GET-HOST-NAME-BY-ADDRESS"
   "GETDOMAINNAME"
   "INTERNET-ADDRESS" 
   "IP-ADDRESS-STRING"
   "STREAM-BYTES-RECEIVED"
   "STREAM-BYTES-TRANSMITTED"
   "STRING-IP-ADDRESS"))

(defpackage "WWW-UTILS"
  (:use)
  #+LispWorks3.2
  (:import-from "CL"   "IGNORABLE")
  #+LispWorks3.2
  (:export    "IGNORABLE")
  #+LispWorks
#+CL-HTTP-SSL
  (:import-from "IPC"
   "UNKNOWN-HOST-NAME"
   "SSL-CLOSED"
   "SSL-CONDITION"
   "SSL-ERROR"
   "SSL-FAILURE")
  #+LispWorks
  (:import-from "CLOS"
   "CLASS-DIRECT-SUPERCLASSES"
   "CLASS-SLOTS"
   "GENERIC-FUNCTION-METHODS"
   "METHOD-SPECIALIZERS"
   "SLOT-DEFINITION-NAME")
  #+LispWorks
  (:import-from "MP"
   "PROCESS-ACTIVE-P"
   "PROCESS-PRESET"
   "PROCESS-WHOSTATE")
  #+LispWorks
  (:import-from "LISPWORKS"
   "CURRENT-PATHNAME")
  #-(or LispWorks3.2 LispWorks4.0 LispWorks4.1 LispWorks4.2 LispWorks4.3)
  (:import-from "SYSTEM"
   "SET-FILE-DATES"
   "SET-FILE-OWNERS")
  (:import-from "RESOURCES"
   "ALLOCATE-RESOURCE"
   "CLEAR-RESOURCE"
   "DEALLOCATE-RESOURCE"
   "DEFRESOURCE"
   "USING-RESOURCE")
  (:export
   "*CONSOLE-LOG-BACKGROUND-COLOR*"
   "*CONSOLE-LOG-FONT*"
   "*CONSOLE-LOG-TEXT-COLOR*"
   "*PRIMARY-NETWORK-HOST*"
   "ABORT-HTTP-STREAM"
   "ALLOCATE-RESOURCE"
   "BAD-CONNECTION-STATE"
   "BYTES-RECEIVED"
   "BYTES-TRANSMITTED"
   "CHUNK-TRANSFER-CONTENT-LENGTH"
   "CHUNK-TRANSFER-DECODING-MODE"
   "CHUNK-TRANSFER-DECODING-MODE-END"
   "CHUNK-TRANSFER-ENCODING-MODE"
   "CLASS-DIRECT-SUPERCLASSES"
   "CLASS-SLOTS"
   "CLEAR-RESOURCE"
   "COMMON-LOGFILE-NOTIFY"
   "CONNECTION-CLOSED"
   "CONNECTION-ERROR"
   "CONNECTION-LOST"
   "CONNECTION-REFUSED"
   "CURRENT-PATHNAME"
   "DEALLOCATE-RESOURCE"
   "DEFAULT-PATHNAME"
   "DEFRESOURCE"
   "DOMAIN-RESOLVER-ERROR"
   "END-OF-CHUNK-TRANSFER-DECODING"
   "EXPOSE-LOG-WINDOW"
   "FILE-NOT-FOUND"
   ;; "FTP-COPY-FILE"
   ;; "FTP-DIRECTORY-INFO"
   "GENERIC-FUNCTION-METHODS"
   "HOST-NOT-RESPONDING"
   "HOST-STOPPED-RESPONDING"
   "LOCAL-NETWORK-ERROR"
   "LOG-WINDOW"
   "LW-COLD-ENABLE-HTTP-SERVICE"
   "MAKE-PROCESS"
   "METHOD-SPECIALIZERS"
   "NETWORK-ERROR"
   "NOTE-FIRST-CHUNK"
   "NOTE-LAST-CHUNK"
   "NOTIFY-LOG-WINDOW"
   #+CL-HTTP-X509
   "PEER-CERTIFICATE"
   #+CL-HTTP-X509
   "PEER-CERTIFICATE-VERIFIED-P"
   "PROCESS-ACTIVE-P"
   "PROCESS-DISABLE"
   "PROCESS-ENABLE"
   "PROCESS-IDLE-TIME"
   "PROCESS-KILL"
   "PROCESS-PRESET"
   "PROCESS-PRIORITY"
   "PROCESS-RESET"
   "PROCESS-RUN-FUNCTION"
   "PROCESS-RUN-TIME"
   "PROCESS-WAIT"
   "PROCESS-WAIT-FOR-STREAM"
   "PROCESS-WAIT-WITH-TIMEOUT"
   "PROCESS-WHOSTATE"
   "PROTOCOL-TIMEOUT"
   "REMOTE-NETWORK-ERROR"
   "SLOT-DEFINITION-NAME"
   #+CL-HTTP-SSL "SSL-CERTIFICATE-REJECTED"
   #+CL-HTTP-SSL "SSL-CLOSED"
   #+CL-HTTP-SSL "SSL-CONDITION"
   #+CL-HTTP-SSL "SSL-CONNECTION-CLOSED"
   #+CL-HTTP-SSL "SSL-CONNECTION-ERROR"
   #+CL-HTTP-SSL "SSL-CONNECTION-REFUSED"
   #+CL-HTTP-SSL "SSL-CIPHER-STRING"
   #+CL-HTTP-SSL "SSL-ERROR"
   #+CL-HTTP-SSL "SSL-FAILURE"
   "TCP-SERVICE-PORT-NUMBER"
   "UNKNOWN-HOST-NAME"
   "USING-RESOURCE"
   "WITH-TIMEOUT"
   "WITH-STREAM-TIMEOUT"))


(defpackage smtp
  (:use future-common-lisp www-utils))
