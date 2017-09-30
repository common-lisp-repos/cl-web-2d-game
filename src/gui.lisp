(in-package :cl-user)
(defpackage cl-web-2d-game.gui
  (:use :cl
        :parenscript
        :ps-experiment
        :cl-ps-ecs)
  (:export :init-gui
           :add-panel-folder
           :add-panel-bool
           :add-panel-number
           :add-panel-button))
(in-package :cl-web-2d-game.gui)

(enable-ps-experiment-syntax)

(defvar.ps *gui-panel* nil)
(defvar.ps *gui-panel-params* nil)

(defun.ps init-gui ()
  (setf *gui-panel* (new (#j.dat.GUI#)))
  (setf *gui-panel-params* (make-hash-table)))

(defmacro.ps add-to-global (name init-value on-change folder &rest args)
  `(progn (setf (gethash ,name *gui-panel-params*) ,init-value)
          ,(append `(-- ((@ (if ,folder ,folder *gui-panel*) add)
                         *gui-panel-params* ,name ,@args))
                   (when on-change
                     `((on-change ,on-change))))))

(defun.ps add-panel-folder (name &key (open-p t))
  (let ((folder (*gui-panel*.add-folder name)))
    (when open-p
      (folder.open))
    folder))

(defun.ps add-panel-bool (name init-value &key (on-change nil) (folder nil))
  (add-to-global name init-value on-change folder))

(defun.ps add-panel-number (name init-value &key (on-change nil) (folder nil) (min -100) (max -100) (step 0.1))
  (add-to-global name init-value on-change folder
                 min max step))

(defun.ps add-panel-button (name &key (on-change nil) (folder nil))
  (add-to-global name on-change folder nil))
