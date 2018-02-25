#|
  This file is a part of cl-web-2d-game project.
  Copyright (c) 2016 eshamster
|#

(in-package :cl-user)
(defpackage cl-web-2d-game-sample-asd
  (:use :cl :asdf))
(in-package :cl-web-2d-game-sample-asd)

(defsystem cl-web-2d-game-sample
  :version "0.1"
  :author "eshamster"
  :license "LLGPL"
  :depends-on (:cl-web-2d-game
               :parenscript
               :ps-experiment
               :cl-ps-ecs
               :cl-markup
               :clack
               :ningle)
  :components ((:module "sample"
                :serial t
                :components
                ((:file "common")
                 (:file "sample-simple")
                 (:file "cl-web-2d-game-sample"))))
  :description "Sample for cl-web-2d-game")
