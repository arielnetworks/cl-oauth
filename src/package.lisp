(defpackage #:oauth
  (:use #:cl #:anaphora #:f-underscore)
  (:import-from #:hunchentoot
                #:create-prefix-dispatcher
                #:*dispatch-table*
                #:*request*
                #:request-method*)
  (:import-from #:alexandria #:with-unique-names #:curry #:rcurry)
  (:import-from #:split-sequence #:split-sequence))

