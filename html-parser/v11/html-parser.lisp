;;; -*- Mode: LISP; Syntax: ANSI-COMMON-LISP; Package: HTML-PARSER -*-
;;
;; Parse an HTML file into a tree of elements. This parser uses the metadata
;; provided by a DTD.
;;
;; Copyright (c) 1996-98,2000 Sunil Mishra <smishra@everest.com>,
;; portions copyright (c) 1999 Kaelin Colclasure <kaelin@acm.org>,
;; all rights reserved.
;;
;; $Id: //depot/cl-http/html-parser-11/html-parser.lisp#1 $
;;
;; This library is free software; you can redistribute it and/or modify it
;; under the terms of the GNU Lesser General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or (at
;; your option) any later version.
;;
;; This library is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
;; General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public License
;; along with this library; if not, write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

(in-package :html-parser)

;;; Parser Initialization

(declaim (inline file-newer-p probe-file*))

(defun file-newer-p (file1 file2)
  (> (file-write-date file1) (file-write-date file2)))

(defun probe-file* (pathname)
  #+(and (or allegro lispworks mcl cmu) (not cl-http))
  (probe-file pathname)
  #+cl-http
  (http::probe-file* pathname))

(defun compile-load-dtd (doctype)
  (let* ((dtd-file (cadr (assoc doctype *html-dtd-list* :test #'string=)))
         (src-file (etypecase dtd-file
		     (pathname dtd-file)
		     (string (make-pathname :host "HTML-PARSER"
					    :name dtd-file
					    :type *source-file-extension*))))
	 (fasl-file (compile-file-pathname src-file)))
    (declare (dynamic-extent fasl-file src-file))
    (when (or (not (probe-file* fasl-file))
              (file-newer-p src-file fasl-file))
      (unwind-protect
	  (compile-file src-file)
	(clear-parameter-entities)))
    (load fasl-file)))

(defun initialize-parser (&optional (doctype *default-dtd*))
  ;; This is the initialization function for initializing the DTD. The
  ;; argument is used to specify the DTD the user wishes to load. If not
  ;; compiled, the DTD compiler is loaded and invoked. The root for the
  ;; DTD is then located, and the lexer is initialized.
  ;;
  ;; To modify the list of DTD's available, look at the definition of
  ;; *HTML-DTD-LIST* in defs.lisp.
  (setq *dtd-tags* nil)
  (compile-load-dtd doctype)
  (set-html-tag-backpointers)
  (set-html-tag-default-containers)
  (define-unknown-tag)
  (initialize-parse-dispatch-functions)
  (setq *current-dtd* doctype)
  t)


;;; Utility functions

(declaim (inline last-saved-structure tag-on-stack-p))

(defun last-saved-structure (parser)
  (let ((pd (find-if #'(lambda (tag-data)
                         (pd-storep tag-data))
                     (parser-stack parser))))
    (and pd (pd-instance pd))))

(defun tag-on-stack-p (tag parser)
  (some #'(lambda (pd)
            (eql (name (pd-instance pd)) (name tag)))
        (parser-stack parser)))

(declaim (inline valid-content-p))

(defun valid-content-p (tag-name container)
  ;; This is a separate function because it ought to be a great deal
  ;; more complex. The function should check with the containment rules
  ;; to ensure that the tag-name can be contained within, taking the
  ;; algebra into consideration. I don't need that.
  (member tag-name (flatten (contains container))))

(defun valid-container-p (container tag-name)
  (or (eql (class-name (class-of container)) 'unknown-tag-instance)
      (and (valid-content-p tag-name container)
           (not (member tag-name (exclusions container))))))

(defun find-unknown-tag-container (parser)
  ;; Find the first tag with non-empty content, and return it.
  ;; Can a tag that has become empty due to exclusions contain an unknown tag?
  ;; [Tentatively, yes.]
  (loop
      with search-start = nil
      for pd in (parser-stack parser)
      for tag-instance = (pd-instance pd)
      for tag-defn = (instance-of tag-instance)
      unless search-start do (setq search-start tag-instance)
      when (or (typep tag-instance 'unknown-tag-instance) (contains tag-defn))
        return tag-instance
      when (inclusions tag-defn) return search-start))

;; 1. Collect exclusions
;; 2. Go up the parser stack.
;;    Search for a path of tags from the given tag that includes tags with
;;    implicit opens and leads to the current stack tag. Any tag in an
;;    exclusion will of course be discarded.
;; 3. If a path is found, return it.

(defun %dynamic-containment (stack)
  (flet ((%extend-containment (current-defn inclusions exclusions)
	   (let ((current-inclusions (inclusions current-defn))
		 (current-exclusions (exclusions current-defn)))
	     (values
	      (append current-inclusions
		      (set-difference inclusions current-exclusions))
	      (append current-exclusions
		      (set-difference exclusions current-inclusions))))))
    (multiple-value-bind (inclusions exclusions)
	(dynamic-containment (cdr stack))
      (%extend-containment (tag-definition (pd-instance (car stack)))
			   inclusions exclusions))))

(defun dynamic-containment (stack)
  (if stack
      (let ((stack-top (car stack)))
	(if (eq (pd-inclusions stack-top) :undefined)
	    (multiple-value-bind (inclusions exclusions)
		(%dynamic-containment stack)
	      (setf (pd-inclusions stack-top) inclusions)
	      (setf (pd-exclusions stack-top) exclusions)
	      (values inclusions exclusions))
	  (values (pd-inclusions stack-top) (pd-exclusions stack-top))))
    (values nil nil)))

(defun deep-find (item tree)
  "Finds item in tree, assuming tree is not circular."
  (when tree
    (cond ((eql item tree) t)
	  ((atom tree) nil)
	  (t (or (deep-find item (car tree))
		 (deep-find item (cdr tree)))))))

(defun find-tag-container (parser tag-instance &aux inclusions exclusions)
  "Returns a list of tags headed by the container tag on the stack that form
the path to the given tag-instance. All tags other than the container must be
instantiated before the given tag may be validly saved."
  (labels ((%path-to-tag (to-instance to from)
	     (if (or (member from inclusions)
		     (and (deep-find from (contains to))
			  (not (member from exclusions))))
		 (list to-instance)
	       (%path-through-implicit-open to-instance to from)))
	   (%path-through-implicit-open (to-instance to from)
	     (loop for container in (containers from)
		 for path = (when (start-optional-p (tag-definition container))
			      (%path-to-tag to-instance to container))
		 when path
		 return (cons container path))))
    (typecase tag-instance
      (unknown-tag-instance (find-unknown-tag-container parser))
      (t (let ((tag-name (name tag-instance)))
	   (multiple-value-setq (inclusions exclusions)
	     (dynamic-containment (parser-stack parser)))
	   (nreverse
	    (loop for stack-frame in (parser-stack parser)
		for stack-instance = (pd-instance stack-frame)
		thereis (%path-to-tag stack-instance
				      (name stack-instance) tag-name))))))))


;;; Context expansion

(defun sort-forms-by-separators (forms separators)
  (when forms
    (mapc #'(lambda (form)
	      (assert (member (car form) separators)))
	  forms)
    (apply #'values (mapcar #'(lambda (separator)
				(cdr (assoc separator forms)))
			    separators))))

#|
(defun sort-forms-by-separators (forms separators)
  (when forms
    (assert (member (car forms) separators))
    (flet ((context-form-p (form)
             (find form separators)))
      (declare (dynamic-extent #'context-form-p))
      (loop for last-keyword = forms then next-keyword
	  for next-keyword = (member-if #'context-form-p (cdr last-keyword))
	  if (member (car last-keyword) keywords :key #'car)
	    do (error "Repeated keyword ~A" (car last-keyword))
	  collect (ldiff last-keyword next-keyword) into keywords
	  while next-keyword
	  finally (return (apply #'values
				 (mapcar #'(lambda (separator)
					     (cdr (assoc separator keywords)))
					 separators)))))))
|#

(defun make-executable-context-form (condition form it-var form-substs)
  (flet ((make-token (object)
           (if (typep object 'html-name-token)
	       object
	     (intern-name-token (string object)))))
    (declare (inline make-token))
    (let ((re-form (rewrite-sexp form :parser-defn :recursive t :duplicates t
				 :bindings form-substs)))
      (cond ((eq condition :any) re-form)
            ((atom condition)
             `((when (eq (name ,it-var) ,(make-token condition))
                 ,.re-form)))
            (t `((when (member (name ,it-var) 
			       ',(mapcar #'make-token condition))
                   ,.re-form)))))))

(defun %save-tag (it its-pd parser)
  (let ((container (last-saved-structure parser)))
    (typecase it
      (abstract-tag-instance
       (when (and container (or (null its-pd) (not (pd-storep its-pd))))
	 (setf (part-of it) container)
	 (push it (parts container)))
       (when its-pd
	 ;; It is unclear what the best course would be if the tag is
	 ;; different from the instance stored in the parser tag stack record.
	 ;; Right now it signals an error. An alternative would be to update.
	 (assert (eq (pd-instance its-pd) it))
	 ;;(unless (eq (pd-instance its-pd) it)
	 ;;  (setf (pd-instance its-pd) it))
	 (unless (pd-storep its-pd)
	   (setf (pd-storep its-pd) t))
	 ))
      (t (when container
           (push it (parts container)))))
    ))

(defun open-tag (it start end parser)
  (let ((stack (parser-stack parser))
        (container-path (or (when (member (name it) *dtd-toplevel-tags*) t)
			    (find-tag-container parser it))))
    ;; Ensure a context where the new tag can open
    (cond ((eq container-path t)
           (when stack
	     ;; #+debug
	     (assert (parser-toplevel-tag parser))
             (close-tag (parser-toplevel-tag parser) start end parser t))
	   (setf (parser-toplevel-tag parser) (name it)))
	  (container-path
           (close-tags-before-container (car container-path) start end parser)
	   (loop for implicit-tag in (cdr container-path)
	       do (open-tag (funcall (parser-make-tag-instance-fn parser)
				     :instance-of (tag-definition
						   implicit-tag))
			    start end parser)))
          (t (open-tag 
	      (funcall (parser-make-tag-instance-fn parser)
		       :instance-of (tag-definition
				     (or (default-container it)
					 (car (containers it)))))
	      start end parser))))
  ;; Open the tag
  (let ((its-pd (make-tag-parser-data
		 :instance it :start-pos start :end-pos end)))
    (push its-pd (parser-stack parser))
    (when (parser-open-tag-fn parser)
      (funcall (parser-open-tag-fn parser) it its-pd start end parser))))

(defun close-tag (tag start end parser &optional implicit-p)
  (when (tag-on-stack-p tag parser)
    (loop 
	for rest-pds on (parser-stack parser)
	for its-pd = (car rest-pds)
	for it = (pd-instance its-pd)
	when (eq (name it) (parser-toplevel-tag parser))
	  do (setf (parser-toplevel-tag parser) nil)
	when (parser-save-fragments parser)
	  do (setf (html-fragment it)
	       (subreference (parser-input parser) (pd-start-pos its-pd)
			     (if (or implicit-p
				     (not (eq (name tag) (name it))))
				 start
			       end)))
	do (setf (parts it) (nreverse (parts it)))
	   (when (parser-close-tag-fn parser)
	     (funcall (parser-close-tag-fn parser) it its-pd start end parser))
	until (eq (name tag) (name it))
	finally (setf (parser-stack parser) (cdr rest-pds)))))

(defun close-tags-before-container (container start end parser)
  (let ((stack (parser-stack parser)))
    (or (eq (pd-instance (car stack)) container)
        (do ((rest-pds stack (cdr rest-pds)))
            ((or (null (cdr rest-pds))
                 (eq (pd-instance (cadr rest-pds)) container))
             (if (null (cdr rest-pds))
		 (error "Tag ~A not found on stack" container)
               (close-tag (pd-instance (car rest-pds)) start end parser
			  t)))))))

(defun add-cdata (it start end parser)
  (when (parser-cdata-fn parser)
    (funcall (parser-cdata-fn parser) it start end parser)))

(defun add-pcdata-as-needed (it start end parser)
  (cond ((and (stringp it) (every #'html-whitespace-p it))
	 ;; Save an empty string only if the immediate tag may contain PCDATA
	 (when (and (parser-pcdata-fn parser)
		    (parser-stack parser)
		    (deep-find #t"pcdata" 
			       (contains
				(pd-instance (car (parser-stack parser))))))
	   (funcall (parser-pcdata-fn parser) it start end parser)))
	(t
	 ;; Ensure a PCDATA container
	 (let ((container-path (find-tag-container parser #t"PCDATA")))
	   (cond (container-path
		  (close-tags-before-container (car container-path)
					       start end parser)
		  (dolist (implicit-tag (cdr container-path))
		    (open-tag (funcall (parser-make-tag-instance-fn parser)
				       :instance-of (tag-definition
						     implicit-tag))
			      start end parser)))
		 (t
		  (open-tag (funcall (parser-make-tag-instance-fn parser)
				     :instance-of (tag-definition
						   *pcdata-default-container*))
			    start end parser))))
	 ;; Do the PCDATA stuff
	 (when (parser-pcdata-fn parser)
	   (funcall (parser-pcdata-fn parser) it start end parser)))))

;; There is a small problem with the way return values from contexts
;; work. Let me give the example of my template matcher. The body
;; matcher context returns #t"body" when it is done. If the document
;; does not have an explicity </body>, the close of body appears as
;; an *eof*. So, the end result of the parse is the parsed body tag.
;; However, the program would like to have the parsed HTML tag as
;; the end result. There is no way to reconcile this conflict at
;; present, and is quite frankly not worth the effort. It will most
;; likely involve a fairly clever language extension.

;; Add an on-eof statement to the contexts. That way, if the parser
;; runs out of text, we can tell it what to do. It will do that, and
;; the exit value shall be set to HTML. While closing the remaining
;; open tags, the body forms shall be run, which will set the space
;; model of the matcher-data, while the exit value shall not be
;; affected since one has already been set. I think this solution
;; shall take care of this issue adequately.

(defmacro without-exits (&rest forms)
  `(let ((*ignore-exits* t))
    (declare (special *ignore-exits*))
    ,.forms))

(defmacro define-html-parser-context
    (name arguments
     &rest forms
     &aux (exitp-var (gensym))
	  (exit-value-var (gensym))
	  (parser-var (intern "PARSER" *package*))
	  (it-var (intern "IT" *package*))
	  (its-pd-var (intern "ITS-PD" *package*))
	  (start-var (intern "START" *package*))
	  (end-var (intern "END" *package*))
	  (save-var (intern "SAVE" *package*))
	  (exit-context-var (intern "EXIT-CONTEXT" *package*)))
  (let ((form-substs `((?exitp-var . ,exitp-var)
		       (?exit-value-var . ,exit-value-var)
		       (?exit-context . ,exit-context-var)
		       (?save . ,save-var)
		       (?it . ,it-var)
		       (?its-pd . ,its-pd-var))))
    (declare (dynamic-extent form-substs))
    (multiple-value-bind
	(use-variables on-open-tag on-cdata on-pcdata on-close-tag on-eof)
	(sort-forms-by-separators forms '(:use-variables 
					  :on-open-tag 
					  :on-cdata 
					  :on-pcdata 
					  :on-close-tag 
					  :on-eof))
      (declare (dynamic-extent use-variables 
			       on-open-tag 
			       on-cdata
			       on-pcdata
			       on-close-tag
			       on-eof))      
      `(defun ,name (parser ,.arguments
		     ,@(unless (member '&aux arguments) '(&aux))
		     ,.use-variables ,exitp-var ,exit-value-var *ignore-exits*)
	 (declare (special *ignore-exits*))
	 (labels ((,save-var (it &optional its-pd)
		    (%save-tag it its-pd parser))
		  ,.(when on-open-tag
		      `((execute-open-tag-forms 
			 (,it-var ,its-pd-var ,start-var ,end-var ,parser-var)
                         ,it-var ,start-var ,end-var ,parser-var
                         (unless (or (member ',name (pd-contexts ,its-pd-var))
				     ,exitp-var)
		           (push ',name (pd-contexts ,its-pd-var))
			   ,.(loop for form in on-open-tag
				 nconc (make-executable-context-form 
					(car form) (cdr form)
					it-var form-substs))))))
		  ,.(when on-close-tag
		      `((execute-close-tag-forms 
			 (,it-var ,its-pd-var ,start-var ,end-var
				  ,parser-var)
                         ,it-var ,its-pd-var ,start-var ,end-var ,parser-var
                         (unless ,exitp-var
                           ,.(loop for form in on-close-tag
				 nconc (make-executable-context-form 
					(car form) (cdr form)
					it-var form-substs))))))
		  ,.(when on-cdata
		      `((execute-cdata-forms 
			 (,it-var ,start-var ,end-var ,parser-var
				  &aux (,its-pd-var nil))
                         ,its-pd-var ,it-var ,start-var ,end-var ,parser-var
                         (unless ,exitp-var
                           ,.(make-executable-context-form
			      :any on-cdata it-var form-substs)))))
		  ,.(when on-pcdata
		      `((execute-pcdata-forms 
			 (,it-var ,start-var ,end-var ,parser-var
				  &aux (,its-pd-var nil))
                         ,its-pd-var ,it-var ,start-var ,end-var ,parser-var
                         (unless ,exitp-var
                           ,.(make-executable-context-form
			      :any on-pcdata it-var form-substs)))))
		  ,.(when on-eof
		      `((execute-eof-forms 
			 (,start-var ,end-var ,parser-var)
			 ,start-var ,end-var ,parser-var
			 (unless ,exitp-var
			   ,.(make-executable-context-form 
			      :any on-eof nil form-substs))))))
	   (declare (dynamic-extent 
		     ,@(when on-open-tag '(#'execute-open-tag-forms))
		     ,@(when on-close-tag '(#'execute-close-tag-forms))
		     ,@(when on-cdata '(#'execute-cdata-forms))
		     ,@(when on-pcdata '(#'execute-pcdata-forms))
		     ,@(when on-eof '(#'execute-eof-forms)))
		    (inline ,save-var))
	   (setf (parser-open-tag-fn parser) 
	     ,(when on-open-tag '#'execute-open-tag-forms)
	     (parser-close-tag-fn parser) 
	     ,(when on-close-tag '#'execute-close-tag-forms)
	     (parser-cdata-fn parser) 
	     ,(when on-cdata '#'execute-cdata-forms)
	     (parser-pcdata-fn parser)
	     ,(when on-pcdata '#'execute-pcdata-forms))
	   ;; test the tags on stack with the open-tag forms
	   (let ((queue (reverse (parser-stack parser))))
	     (declare (dynamic-extent queue))
	     (loop 
		 for pd in queue
		 do (execute-open-tag-forms 
		     (pd-instance pd) pd (pd-start-pos pd)
		     (pd-end-pos pd) parser)
		 when ,exitp-var return (values ,exit-value-var nil)))
	   ;; get more tokens from the input
	   (loop with token-type and token and token-start and token-end
	       do (multiple-value-setq (token-type token token-start token-end)
		    (next-html-token parser))
		  (case token-type
		    ((:comment :declaration) nil)
		    (:open-tag (open-tag token token-start token-end parser))
		    (:close-tag (close-tag token token-start token-end parser))
		    (:cdata (add-cdata token token-start token-end parser))
		    ((:character :pcdata :entity)
		     (add-pcdata-as-needed token token-start token-end parser))
		    (t (assert (eq token-type *eof*))
		       ,@(when on-eof
			   `((execute-eof-forms token-start token-end parser)))
		       (close-tag (parser-toplevel-tag parser)
				  token-start token-end parser)))
	       until (or ,exitp-var (eq token-type *eof*))
	       finally (return (values ,exit-value-var 
				       (eq token-type *eof*)))))))))


;;; Parser expansion

(defun make-context-transitions (transitions parser-var last-context-var
				 last-value-var)
  (labels ((%transition-test-form (from-transition test)
	     (cond ((eq test t)
		    `(eq ,last-context-var ',from-transition))
		   ((atom test)
		    `(and (eq ,last-context-var ',from-transition)
			  (eq (name ,last-value-var)
			      ,(if (typep test 'html-name-token)
				   test
				 (intern-name-token (string test))))))
		   ((eq (car test) 'function)
		    `(and (eq ,last-context-var ',from-transition)
			  (funcall ,test ,last-value-var)))
		   ((eq (car test) :eval)
		    `(and (eq ,last-context-var ',from-transition)
			  (eq ,last-value-var (progn ,(cdr test)))))
		   (t (error "Unrecognized test condition ~A" test))))
	   (%transition-call-form (call)
	     (if (eq call :end)
		 `(values :end ,last-value-var)
	       `(multiple-value-bind (,last-value-var eofp)
		    (,(car call) ,parser-var ,.(cdr call))
		  (if eofp
		      (values :end ,last-value-var)
		    (values ',(car call) ,last-value-var)))))
	   (%make-context-transition (transition)
	     (if (eq (car transition) :start)
		 (destructuring-bind (next-context) (cdr transition)
		   `((eq ,last-context-var :start)
		     ,(%transition-call-form next-context)))
	       (destructuring-bind (switch-test next-context) (cdr transition)
		 `(,(%transition-test-form (car transition) switch-test)
		   ,(%transition-call-form next-context))))))
    `(cond
      ,.(mapcar #'%make-context-transition transitions)
      (t (error "Unspecified action for transition condition")))))

(defmacro define-html-parser (name args &rest forms
                              &aux (input-var (gensym "IN"))
			           (save-frag-var (gensym "SFV"))
				   (parser-var (gensym "PV"))
				   (last-context-var (gensym "LCV"))
				   (last-value-var (intern "IT" *package*))
				   (make-tag-instance-fn-var (gensym "MTF")))
  (multiple-value-bind
      (initialization transitions)
      (sort-forms-by-separators forms '(:initialization :transitions))
    (declare (dynamic-extent initialization transitions))
    
    (let* ((key-args (member '&key args))
           (post-key-args (when (null key-args)
                            (or (member '&rest args)
                                (member '&aux args)))))
      `(progn
         (defun ,name (,input-var ,.(ldiff args (or key-args post-key-args))
		       &key ((:save-fragments ,save-frag-var) nil)
			    ((:make-tag-instance-fn ,make-tag-instance-fn-var)
			     #'parser-make-tag-instance)
			    ,.(if key-args (cdr key-args) post-key-args))
           (flet ((do-transition 
		      (,parser-var ,last-context-var ,last-value-var)
                    ,(make-context-transitions 
		      transitions parser-var last-context-var last-value-var)))
             ,.initialization
             (loop 
		 with ,last-context-var = :start
		 and ,last-value-var
		 and ,parser-var = (make-parser
				    :input ,input-var
				    :save-fragments ,save-frag-var
				    :make-tag-instance-fn
				    ,make-tag-instance-fn-var)
		 do (multiple-value-setq (,last-context-var ,last-value-var)
		      (do-transition 
			  ,parser-var ,last-context-var ,last-value-var))
		 until (eq ,last-context-var :end)
		 finally (return ,last-value-var))))))))


;;; At startup...

;;(initialize-parser)

;;; EOF