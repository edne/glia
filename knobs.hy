#!/usr/bin/env hy
(import [glia [on-serial run read-line]])
(import [glia [to-osc send]])
(import re)


(defn init-knobs [device]
  (run device `(dotimes (kn 8)
                 (pinmode (+ kn 14) nil))))


(defn defun-print-knob [device]
  (run device `(defun pkn (pin)
                 (print (quote >))
                 (princ (quote knb))
                 (princ (- pin 14))
                 (princ (quote =))
                 (princ (analogread pin))
                 )))


(defn defun-get-data [device]
  (run device `(defun gdt ()
                 (dotimes (kn 8)
                   (pkn (+ kn 14)))
                 (print (quote eod))  ;; End Of Data
                 )))


(defn get-data [device]
  (run device `(gdt)))


(defn parse-knob [line]
  (let [[extract (fn [pattern]
                   (-> (re.search pattern line) .groups first int))]
        [number (extract "knb(.+)=")]
        [value  (extract "=(.+)\r")]]
    [number value]))


(defn parse-data [line]
  (cond
    [(in "knb" line) ["knob" (parse-knob line)]]
    [true nil]  ;; filtered away
    ))


(defn read-data [device]
  (let [[read-line* (fn [] (read-line device))]
        [data?      (fn [line] (not (.startswith line "eod")))]
        [to-dict    (fn [data]  ;; assoc is not pure
                      (setv d {})
                      (for [[type [id value]] data]
                        (if-not (in type (.keys d)) (assoc d type {}))
                        (assoc (get d type) id value))
                      d)]]
    (get-data device)
    (->> (repeatedly read-line*)
      (take-while data?)
      (map parse-data)
      (filter identity)  ;; empty or invalid lines
      ;to-dict
      )))


(defn init-data-stream [device]
  (init-knobs       device)
  (defun-print-knob device)
  (defun-get-data   device))


(defn read-data-stream [device]
  (repeatedly (fn [] (read-data device))))


(to-osc "localhost:7172"
        (fn [addr]
          (on-serial "/dev/ttyUSB0"
                     (fn [device]
                       (init-data-stream device)
                       (while true
                         (let [[data  (first (read-data-stream device))]]
                           (for [[type [id value]] data]
                             (send addr
                                   (.format "controller/{}{}" type id)
                                   (/ value 1023)))))))))
