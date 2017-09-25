#!/bin/sh
#|-*- mode:lisp -*-|#
#| <Put a one-line description here>
exec ros -Q -- $0 "$@"
|#
;;; vim: set ft=lisp lisp:

(progn ;;init forms
  (ros:ensure-asdf)
  #+quicklisp (ql:quickload '(:ps-experiment
                              :cl-ps-ecs
                              :cl-web-2d-game
                              :ningle
                              :cl-markup
                              :clack)
                            :silent t))

(defpackage :ros.script.sample-collision
  (:use :cl
        :cl-markup
        :cl-ps-ecs
        :ps-experiment
        :cl-web-2d-game))
(in-package :ros.script.sample-collision)

;; --- Definitions about directories --- ;;

(defvar *script-dir*
  (merge-pathnames "sample/"
                   (asdf:component-pathname
                    (asdf:find-system :cl-web-2d-game))))

(defvar *js-relative-dir* "js/")

(defvar *downloaded-js-dir*
  (merge-pathnames *js-relative-dir* *script-dir*))

;; --- Parenscript program --- ;;

(defvar *js-game-file*
  (merge-pathnames "sample.js" *downloaded-js-dir*))

(defun.ps+ add-mouse-pointer ()
  (let ((pointer (make-ecs-entity))
        (point (make-point-2d))
        (r 30))
    (add-ecs-component-list
     pointer
     point
     (make-script-2d :func (lambda (entity)
                             (declare (ignore entity))
                             (with-slots (x y) point
                               (setf x (get-mouse-x))
                               (setf y (get-mouse-y)))))
     (make-physic-circle :r r))
    (add-ecs-entity pointer)))

;; [WIP]
(defun.ps+ add-colliders ()
  (let* ((entity (make-ecs-entity))
         (r 40)
         (model (make-model-2d :model (make-solid-circle :r r :color #x888888)
                               :depth 0))
         (collide-p nil))
    (add-ecs-component-list
     entity
     (make-point-2d :x 200 :y 200)
     (make-physic-circle :r r
                         :on-collision (lambda (mine target)
                                         (declare (ignore mine target))
                                         (setf collide-p t)))
     (make-script-2d :func (lambda (entity)
                             (if collide-p
                                 (progn (setf collide-p nil)
                                        (enable-model-2d entity :target-model-2d model))
                                 (disable-model-2d entity :target-model-2d model))))
     model)
    (add-ecs-entity entity)))

(defun.ps+ init-func (scene)
  (init-gui)
  (initialize-input)
  (add-mouse-pointer)
  (add-colliders)
  (add-panel-bool 'display-collider-model t
                  :on-change (lambda (value)
                               (setf-collider-model-enable value)))
  (init-default-systems :scene scene))

(defun.ps+ update-func ()
  )

;; --- Make js main file --- ;;

(defun make-js-main-file ()
  (with-open-file (out *js-game-file*
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
    (princ
     (pse:with-use-ps-pack (:this)
       (let ((width 800)
             (height 600))
         (start-2d-game :screen-width width
                        :screen-height height
                        :camera (init-camera 0 0 width height)
                        :rendered-dom (document.query-selector "#renderer")
                        :stats-dom (document.query-selector "#stats-output")
                        :monitoring-log-dom (document.query-selector "#monitor")
                        :event-log-dom (document.query-selector "#eventlog")
                        :init-function init-func
                        :update-function update-func)))
     out)))

;; --- Server --- ;;

(defvar *app* (make-instance 'ningle:<app>))

(defvar *server* nil)

(setf (ningle:route *app* "/" :method :GET)
      (lambda (params)
        (declare (ignorable params))
        (make-js-main-file)
        (with-output-to-string (str)
          (let ((cl-markup:*output-stream* str))
            (html5 (:head
                    (:title "test")
                    (dolist (js-src (make-src-list-for-script-tag *js-relative-dir*))
                      (markup (:script :src js-src nil))))
                   (:body
                    (:div :id "stats-output")
                    (:div :id "renderer" nil)
                    (:div :id "monitor" "(for Monitoring Log)")
                    (:div (:pre :id "eventlog" "(for Event Log)"))
                    (:script :src "js/sample.js" nil)))))))

(defun stop ()
  (when *server*
    (clack:stop *server*)
    (setf *server* nil)))

(defun run (&key (port 5000))
  (ensure-js-files *downloaded-js-dir*)
  (stop)
  (setf *server*
        (clack:clackup
         (lack:builder
          (:static :path (lambda (path)
                           (print path)
                           (if (ppcre:scan "^(?:/images/|/css/|/js/|/robot\\.txt$|/favicon\\.ico$)"
                                           path)
                               path
                               nil))
                   :root *script-dir*)
          *app*)
         :port port)))

;; --- Roswell script main --- ;;

(defun main (&rest argv)
  (declare (ignorable argv))
  (run :port 16896)
  (princ "--- Press enter key to stop ---")
  (peek-char)
  (stop))
