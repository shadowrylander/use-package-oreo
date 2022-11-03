;;; use-package-oreo.el --- auto install system packages  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Justin Talbott

;; Author: Justin Talbott <justin@waymondo.com>, Jeet Ray <jeet.ray@syvl.org>
;; Keywords: convenience, tools, extensions
;; URL: https://github.com/syvlorg/use-package-oreo
;; Version: 0.2
;; Package-Requires: ((use-package "2.1") (oreo-packages "1.0.4"))
;; Filename: use-package-oreo.el
;; License: GNU General Public License version 3, or (at your option) any later version
;;

;;; Commentary:
;;
;; The `:oreo` keyword allows you to ensure system
;; binaries exist alongside your `use-package` declarations.
;; This version is adapted from the updated version over at
;; https://github.com/jwiegley/use-package/blob/master/use-package-oreo.el
;; 

;;; Code:

(require 'use-package)
(require 'oreo-packages nil t)

(eval-when-compile
  (declare-function oreo-packages-get-command "oreo-packages"))


(defun use-package-oreo-consify (arg)
  "Turn `arg' into a cons of (`package-name' . `install-command')."
  (cond
   ((stringp arg)
    (cons arg `(oreo-packages-install ,arg)))
   ((symbolp arg)
    (cons arg `(oreo-packages-install ,(symbol-name arg))))
   ((consp arg)
    (cond
     ((not (cdr arg))
      (use-package-oreo-consify (car arg)))
     ((stringp (cdr arg))
      (cons (car arg) `(async-shell-command ,(cdr arg))))
     (t
      (cons (car arg)
	    `(oreo-packages-install ,(symbol-name (cdr arg)))))))))

;;;###autoload
(defun use-package-normalize/:oreo (_name-symbol keyword args)
  "Turn `arg' into a list of cons-es of (`package-name' . `install-command')."
  (use-package-only-one (symbol-name keyword) args
    (lambda (_label arg)
      (cond
       ((and (listp arg) (listp (cdr arg)))
        (mapcar #'use-package-oreo-consify arg))
       (t
        (list (use-package-oreo-consify arg)))))))

(defun use-package-oreo-exists? (file-or-exe)
  "If variable is a string, ensure the file path exists.
If it is a symbol, ensure the binary exist."
  (if (stringp file-or-exe)
      (file-exists-p file-or-exe)
    (executable-find (symbol-name file-or-exe))))


;;;###autoload
(defun use-package-handler/:oreo (name _keyword arg rest state)
  "Execute the handler for `:oreo' keyword in `use-package'."
  (let ((body (use-package-process-keywords name rest state)))
    (use-package-concat
     (mapcar #'(lambda (cons)
                 `(unless (use-package-oreo-exists? ',(car cons))
		    ,(cdr cons))) arg)
     body)))

(add-to-list 'use-package-keywords :oreo t)

(provide 'use-package-oreo)

;;; use-package-oreo.el ends here
