
(asdf:oos 'asdf:load-op 'cl-oauth)
(asdf:oos 'asdf:load-op 'hunchentoot)

(defpackage :cl-oauth.google-consumer
  (:use :cl :cl-oauth))

(in-package :cl-oauth.google-consumer)

;;; Google requires the timestamp to be synced to Unix time.
(defconstant +unix-to-universal-time+ 2208988800)

(defun get-unix-time (&optional (ut (get-universal-time)))
  (- ut +unix-to-universal-time+))


;;; insert your credentials and auxiliary information here.
(defparameter *key* "wintermute.mine.nu") 
(defparameter *secret* "L3YtuVz9EYU/dkrHnM7UD72c") 
(defparameter *callback-uri* "http://wintermute.mine.nu/")


;;; go
(defparameter *get-request-token-endpoint* "https://www.google.com/accounts/OAuthGetRequestToken")
(defparameter *auth-request-token-endpoint* "https://www.google.com/accounts/OAuthAuthorizeToken")
(defparameter *get-access-token-endpoint* "https://www.google.com/accounts/OAuthGetAccessToken")
(defparameter *consumer-token* (make-consumer-token :key *key* :secret *secret*))
(defparameter *request-token* nil)
(defparameter *access-token* nil)

(defun get-access-token ()
  (obtain-access-token *get-access-token-endpoint*
                       *consumer-token* *request-token*
                       :timestamp (get-unix-time)))

;;; get a request token
(defun get-request-token (scope)
  ;; TODO: scope could be a list.
  (obtain-request-token
    *get-request-token-endpoint*
    *consumer-token*
    :timestamp (get-unix-time)
    :callback-uri *callback-uri*
    :user-parameters `(("scope" . ,scope))))

(setf *request-token* (get-request-token "http://www.google.com/calendar/feeds/"))

(let ((auth-uri (make-authorization-uri *auth-request-token-endpoint* *request-token*)))
  (format t "Please authorize the request token at this URI: ~A~%" (puri:uri auth-uri)))


;;; set up callback uri
(defun callback-dispatcher (request)
  (declare (ignorable request))
  (unless (cl-ppcre:scan  "favicon\.ico$" (hunchentoot:script-name request))
    (lambda (&rest args)
      (declare (ignore args))
      (handler-case
          (authorize-request-token-from-request
            (lambda (rt-key)
              (assert *request-token*)
              (unless (equal (url-encode rt-key) (token-key *request-token*))
                (warn "Keys not equal: ~S / ~S~%" (url-encode rt-key) (token-key *request-token*)))
              *request-token*))
        (error (c)
          (warn "Couldn't verify request token authorization: ~A" c)))
      (when (request-token-authorized-p *request-token*)
        (format t "Successfully verified request token with key ~S~%" (token-key *request-token*))
        (setf *access-token* (get-access-token))))))

(pushnew 'callback-dispatcher hunchentoot:*dispatch-table*)


(defvar *web-server* nil)

(when *web-server*
  (hunchentoot:stop *web-server*)
  (setf *web-server* nil))

(setf *web-server* (hunchentoot:start (make-instance 'hunchentoot:acceptor :port 8090)))

