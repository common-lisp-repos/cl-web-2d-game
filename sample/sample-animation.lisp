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

(defpackage :ros.script.sample-animation
  (:use :cl
        :cl-markup
        :cl-ps-ecs
        :cl-web-2d-game)
  (:import-from :ps-experiment
                :defun.ps
                :defvar.ps))
(in-package :ros.script.sample-animation)

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

(defun.ps add-animation-model (&key x y depth texture-name)
  (let ((rect (make-ecs-entity)))
    (add-ecs-component-list
     rect
     (make-point-2d :x x :y y
                    :angle (* 2 PI (random))))
    (make-texture-model-async
     :width 160 :height 160
     :texture-name texture-name
     :callback (lambda (mesh)
                 (get-texture-async
                  texture-name
                  (lambda (texture)
                    (let* ((model-2d (make-model-2d :model mesh :depth depth))
                           (anime-2d (init-animation-2d
                                      :interval 4 :vert-count 5 :horiz-count 3
                                      :model model-2d :texture texture
                                      :animation-end-callback (lambda (anime)
                                                                (if (< (random) 0.5)
                                                                    (delete-ecs-entity rect)
                                                                    (reverse-animation anime))))))
                      (add-ecs-component-list rect model-2d anime-2d))
                    (start-animation anime-2d)
                    (add-ecs-entity-to-buffer rect)))))))

(defun.ps load-textures ()
  (load-texture :path "/images/sample_explosion.png" :name "explosion"
                :alpha-path "/images/sample_explosion_alpha.png"))

(defun.ps init-func (scene)
  (set-console-log-level :debug)
  (load-textures)
  (init-default-systems :scene scene))

(defvar.ps *creation-interval* 20)
(defvar.ps *creation-interval-rest* 0)

(defun.ps count-entity ()
  (let ((count 0))
    (do-ecs-entities entity
      (incf count))
    count))

(defun.ps update-func ()
  (add-to-monitoring-log (count-entity))
  (decf *creation-interval-rest*)
  (when (<= *creation-interval-rest* 0)
    (setf *creation-interval-rest*
          (floor (* (random) *creation-interval*)))
    (add-animation-model :texture-name "explosion"
                         :x (+ 80 (* (random 480)))
                         :y (+ 80 (* (random 320)))
                         :depth 10)))

;; --- Make js main file --- ;;

(defun make-js-main-file ()
  (with-open-file (out *js-game-file*
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
    (princ
     (pse:with-use-ps-pack (:this)
       (let ((width 640)
             (height 480))
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
