(defpackage cl-web-2d-game/t/calc
  (:use :cl
        :rove
        :cl-ps-ecs
        :ps-experiment/t/test-utils
        :cl-web-2d-game/core/basic-components
        :cl-web-2d-game/utils/calc
        :cl-web-2d-game/t/test-utils)
  (:import-from :ps-experiment
                :defmacro.ps+
                :defun.ps+
                :defvar.ps+))
(in-package :cl-web-2d-game/t/calc)

;; --- test --- ;;

(defun.ps+ easy-vector-angle (x y)
  (vector-angle (make-vector-2d :x x :y y)))

(deftest.ps+ for-vector-calculations
  (testing "vector-abs"
    (ok (= (round (vector-abs
                   (make-vector-2d :x 3 :y 4)))
           5))
    (ok (= (round (vector-abs
                   (make-vector-2d :x 4 :y -3)))
           5))) 
  (testing "vector-angle"
    (testing "when x = 0"
      (ok (within-angle (easy-vector-angle 0 100) (/ PI 2)))
      (ok (within-angle (easy-vector-angle 0 -100) (/ PI -2))))
    (testing "when x != 0"
      (ok (within-angle (easy-vector-angle 100 0) 0))
      (ok (within-angle (easy-vector-angle -100 0) PI)))
    (testing "other cases"
      (ok (within-angle (easy-vector-angle  10  10) (* 1 (/ PI 4))))
      (ok (within-angle (easy-vector-angle -10  10) (* 3 (/ PI 4))))
      (ok (within-angle (easy-vector-angle -10 -10) (* -3 (/ PI 4))))
      (ok (within-angle (easy-vector-angle  10 -10) (* -1 (/ PI 4))))))
  (testing "calc-inner-product"
    (ok (= (calc-inner-product (make-vector-2d :x 1 :y 2)
                               (make-vector-2d :x -3 :y 4))
           5)))
  (testing "calc-outer-product-z"
    (ok (= (calc-outer-product-z (make-vector-2d :x 1 :y 2)
                                 (make-vector-2d :x 3 :y 9))
           3))
    (ok (= (calc-outer-product-z (make-vector-2d :x 1 :y 2)
                                 (make-vector-2d :x 3 :y -9))
           -15))))

(deftest.ps+ for-vector-modification
  (testing "Test incf-vector and dicf-vector"
    (let ((target (make-vector-2d :x 10 :y 10))
          (diff (make-vector-2d :x 5 :y -5)))
      (incf-vector target diff)
      (ok (= (vector-2d-x target) 15))
      (ok (= (vector-2d-y target) 5))
      (ok (= (vector-2d-x diff) 5))
      (ok (= (vector-2d-y diff) -5)))
    (let ((target (make-vector-2d :x 10 :y 10))
          (diff (make-vector-2d :x 5 :y -5)))
      (decf-vector target diff)
      (ok (= (vector-2d-x target) 5))
      (ok (= (vector-2d-y target) 15))
      (ok (= (vector-2d-x diff) 5))
      (ok (= (vector-2d-y diff) -5))))
  (testing "setf-vector-abs"
    (let* ((target (make-vector-2d :x 10 :y 10))
           (before-angle (vector-angle target)))
      (setf-vector-abs target 200)
      (ok (within-length (vector-abs target) 200))
      (ok (within-angle (vector-angle target) before-angle))))
  (testing "Test rotation functions"
    (testing "setf-vector-angle"
      (let* ((target (make-vector-2d :x 10 :y 10))
             (before-len (vector-abs target)))
        (setf-vector-angle target (* PI 1/3)) 
        (ok (within-length (vector-abs target) before-len))
        (ok (within-angle (vector-angle target) (* PI 1/3)))))
    (testing "incf-rotate-diff and decf-rotate-diff"
      ;; Now, test only case where the center of rotation is (0, 0)
      (let* ((radious 10)
             (target (make-vector-2d :x radious :y 0)))
        (flet ((prove-angle (expected-angle)
                 (ok (within-length (vector-abs target) radious))
                 (ok (within-angle (vector-angle target) expected-angle))))
          (incf-rotate-diff target radious 0 (* PI 1/3))
          (prove-angle (* PI 1/3))
          (incf-rotate-diff target radious (* PI 1/3) (* PI 1/3))
          (prove-angle (* PI 2/3))
          (decf-rotate-diff target radious (* PI 2/3) (* PI 1/6))
          (prove-angle (* PI 1/2)))))
    (testing "rotatef-point-by"
      (let* ((radious 10)
             (target (make-point-2d :x radious :y 0))
             (speed (* PI 1/3))
             (rotator (make-rotate-2d :speed speed :radious radious)))
        (flet ((prove-angle (expected-angle)
                 (ok (within-length (vector-abs target) radious))
                 (ok (within-angle (vector-angle target) expected-angle))
                 (ok (within-angle (point-2d-angle target) expected-angle))
                 (ok (within-angle (rotate-2d-angle rotator) expected-angle))))
          (rotatef-point-by target rotator)
          (prove-angle speed)
          (rotatef-point-by target rotator)
          (prove-angle (* speed 2)))))
    (testing "movef-vector-to-circle"
      ;; Now, test only case where the center of rotation is (0, 0)
      (let ((point (make-point-2d :x 0 :y 0 :angle 0)))
        (movef-vector-to-circle point 5 (* PI 2/3))
        (ok (within-length (vector-abs point) 5))
        (ok (within-angle (vector-angle point) (* PI 2/3)))
        (ok (= (point-2d-angle point) (* PI 2/3)))))))

(deftest.ps+ for-coordinate-functions
  (testing "transformf-point"
    ;; Note: (0, 0), (1, (sqrt 3)), (2, 0) are points of a regular triangle. 
    (let ((base (make-point-2d :x 1 :y (sqrt 3) :angle (* PI -1/2)))
          (target (make-point-2d :x (sqrt 3) :y 1 :angle (* PI 1/4))))
      (transformf-point target base)
      ;; check the target is transformed
      (ok (is-point target 2 0 (* PI -1/4)))
      ;; check the base is not changed
      (ok (is-point base 1 (sqrt 3) (* PI -1/2)))))
  (testing "calc-global-point and calc-local-point"
    (let ((grand-parent (make-ecs-entity))
          (parent (make-ecs-entity))
          (stranger (make-ecs-entity))
          (child (make-ecs-entity)))
      (add-ecs-component (make-point-2d :x 0 :y 1 :angle (* PI -1/2))
                         parent)
      (add-ecs-component (make-point-2d :x 0 :y 1 :angle (* PI -1/2))
                         grand-parent)
      (add-ecs-component (make-point-2d :x 0 :y 1 :angle (* PI -1/2))
                         child)
      (setf (ecs-entity-parent child) stranger)
      (setf (ecs-entity-parent stranger) parent)
      (setf (ecs-entity-parent parent) grand-parent)
      (let ((global-pnt (calc-global-point child)))
        (ok (is-point global-pnt 1 0 (* PI -3/2)))
        (ok (is-point (calc-local-point child global-pnt) 0 1 (* PI -1/2))))
      (let* ((offset (make-point-2d :x 0 :y 1 :angle (* PI -1/2)))
             (result (calc-global-point child offset)))
        (ok (is-point result 0 0 (* PI -2)))
        (ok (is-point offset 0 1 (* PI -1/2)))))))

(deftest.ps+ for-point-to-point-distance
  (testing "calc-dist"
    (let ((pnt1 (make-vector-2d :x 2 :y -2))
          (pnt2 (make-vector-2d :x -1 :y 2))
          (expected 5))
      (ok (within-length (calc-dist pnt1 pnt2) expected))
      (ok (within-length (calc-dist pnt2 pnt1) expected))))
  (testing "calc-dist-p2"
    (let ((pnt1 (make-vector-2d :x 2 :y -2))
          (pnt2 (make-vector-2d :x -1 :y 2))
          (expected 25))
      (ok (within-length (calc-dist-p2 pnt1 pnt2) expected))
      (ok (within-length (calc-dist-p2 pnt2 pnt1) expected)))))

(deftest.ps+ for-point-to-line-distance
  (testing "calc-dist-to-line"
    (let ((line-pnt1 (make-vector-2d :x 0 :y 0))
          (line-pnt2 (make-vector-2d :x 1 :y 1)))
      (ok (within-length (calc-dist-to-line (make-vector-2d :x 0 :y 1)
                                            line-pnt1 line-pnt2)
                         (/ 1 (sqrt 2))))
      (ok (within-length (calc-dist-to-line (make-vector-2d :x 0 :y -1)
                                            line-pnt1 line-pnt2)
                         (/ 1 (sqrt 2)))))
    ;; line-pnt1.x == line-pnt2.x 
    (let ((line-pnt1 (make-vector-2d :x 1 :y 0))
          (line-pnt2 (make-vector-2d :x 1 :y 1)))
      (ok (within-length (calc-dist-to-line (make-vector-2d :x 0 :y 1)
                                            line-pnt1 line-pnt2)
                         1))
      (ok (within-length (calc-dist-to-line (make-vector-2d :x 0 :y -1)
                                            line-pnt1 line-pnt2)
                         1))))
  (testing "calc-dist-to-line-seg"
    (let ((line-pnt1 (make-vector-2d :x 0 :y 1))
          (line-pnt2 (make-vector-2d :x 1 :y 0)))
      (flet ((is-dist (x y expected)
               (ok (within-length
                    (calc-dist-to-line-seg (make-vector-2d :x x :y y)
                                           line-pnt1 line-pnt2)
                    expected))))
        ;; The following points are on the line passing throw (2, 1) and (1, 2).
        (is-dist 3 0 2)
        (is-dist 2 1 (sqrt 2))
        (is-dist 1.5 1.5 (sqrt 2))
        (is-dist 1 2 (sqrt 2))
        (is-dist 0 3 2)))))

(deftest.ps+ for-miscs
  (testing "adjust-to-target"
    (ok (= (adjust-to-target -1 8 2) 1))
    (ok (= (adjust-to-target 7 8 2) 8))
    (ok (= (adjust-to-target 8 -1 2) 6))
    (ok (= (adjust-to-target 1 -1 2) -1))
    (ok (signals (adjust-to-target 1 -1 -1) 'simple-error)))
  (testing "lerp-scalar"
    (let ((tolerance 0.0001))
      (ok (within (lerp-scalar 5 10 0)
                  5 tolerance))
      (ok (within (lerp-scalar 5 10 1)
                  10 tolerance))
      (ok (within (lerp-scalar 5 10 0.1)
                  5.5 tolerance))
      (ok (within (lerp-scalar 5 10 -0.1)
                  4.5 tolerance))
      (ok (within (lerp-scalar 5 10 1.1)
                  10.5 tolerance))))
  (testing "lerp-vector-2d"
    (let ((min-vector (make-vector-2d :x 5 :y 50))
          (max-vector (make-vector-2d :x 10 :y 100)))
      (flet ((is-vector (got expected-x expected-y)
               (ok (within-length (vector-2d-x got) expected-x))
               (ok (within-length (vector-2d-y got) expected-y))))
        (is-vector (lerp-vector-2d min-vector max-vector 0)
                   5 50)
        (is-vector (lerp-vector-2d min-vector max-vector 1)
                   10 100)
        (is-vector (lerp-vector-2d min-vector max-vector 0.1)
                   5.5 55)
        (is-vector (lerp-vector-2d min-vector max-vector -0.1)
                   4.5 45)
        (is-vector (lerp-vector-2d min-vector max-vector 1.1)
                   10.5 105)
        (let ((temp-place (make-point-2d)))
          (lerp-vector-2d min-vector max-vector 0.5 temp-place)
          (is-vector temp-place 7.5 75))))))
