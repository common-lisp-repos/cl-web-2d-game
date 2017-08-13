(in-package :cl-user)
(defpackage cl-web-2d-game.animation
  (:use :cl
        :parenscript
        :ps-experiment
        :cl-ps-ecs
        :cl-web-2d-game.2d-geometry
        :cl-web-2d-game.basic-components
        :cl-web-2d-game.texture
        :cl-web-2d-game.draw-model-system
        :cl-web-2d-game.logger)
  (:export :init-animation-2d
           :start-animation
           :start-reversed-animation
           :stop-animation
           :run-animation-process))
(in-package :cl-web-2d-game.animation)

(enable-ps-experiment-syntax)

;; TODO: Enable to repeat animation
;; TODO: Enable to notify animation end to caller

(defstruct.ps+ (animation-2d (:include ecs-component))
    ;; input parameter
    interval (horiz-count 1) (vert-count 1) model texture
    ;; state parameter
    (goes-to-forward t)
    (runs-animation nil)
    (interval-counter 0)
    (image-counter 0))

(defun.ps+ init-animation-2d (&key interval (horiz-count 1) (vert-count 1) model texture)
  (check-type model model-2d)
  (check-type texture texture-2d)
  (let ((anime (make-animation-2d :interval interval
                                  :horiz-count horiz-count
                                  :vert-count vert-count
                                  :model model
                                  :texture texture)))
    (switch-animation-image anime 0)
    anime))

(defun.ps+ start-animation (anime)
  (with-slots (goes-to-forward interval-counter interval runs-animation) anime
    (unless goes-to-forward
      (setf interval-counter
            (- interval interval-counter 1)))
    (setf runs-animation t)
    (setf goes-to-forward t)))

(defun.ps+ start-reversed-animation (anime)
  (with-slots (goes-to-forward interval-counter interval runs-animation) anime
    (when goes-to-forward
      (setf interval-counter
            (- interval interval-counter 1)))
    (setf runs-animation t)
    (setf goes-to-forward nil)))

(defun.ps+ stop-animation (anime)
  (setf (animation-2d-runs-animation anime) nil))

(defun.ps+ switch-animation-image (anime next-counter)
  (with-slots (model texture image-counter horiz-count vert-count) anime
    (let ((max-count (* horiz-count vert-count)))
      (when (or (< next-counter 0)
                (>= next-counter max-count))
        (error "The target animation counter is invalid (Max: ~D, Got: ~D)"
               max-count next-counter))
      (setf image-counter next-counter)
      (let ((x-count (mod next-counter vert-count))
            (y-count (- horiz-count (floor next-counter vert-count) 1))
            (width (/ 1.0 vert-count))
            (height (/ 1.0 horiz-count)))
        (change-geometry-uvs texture (model-2d-geometry model)
                             (* width x-count) (* height y-count)
                             width height)))))

(defun.ps+ run-animation-process (anime)
  (with-slots (runs-animation goes-to-forward interval interval-counter
                              image-counter horiz-count vert-count) anime
    (when runs-animation
      (if (< (1+ interval-counter) interval)
          (incf interval-counter)
          (when (or (and goes-to-forward (< (1+ image-counter)
                                            (* horiz-count vert-count)))
                    (and (not goes-to-forward) (> image-counter 0)))
            (setf interval-counter 0)
            (switch-animation-image anime
                                    (if goes-to-forward
                                        (1+ image-counter)
                                        (1- image-counter))))))))
