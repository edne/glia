#!/usr/bin/env hy
(import [glia [on-serial run read-line]])
(import re)


(defn device-init-knobs [port]
  (run port `(dotimes (kn 8)
               (pinmode (+ kn 14) nil))))


(defn device-defun-print-knob [port]
  (run port `(defun pkn (pin)
               (print (quote >))
               (princ (quote knb))
               (princ (- pin 14))
               (princ (quote =))
               (princ (analogread pin))
               )))


(defn device-defun-get-data [port]
  (run port `(defun gdt ()
               (dotimes (kn 8)
                 (pkn (+ kn 14)))
               (print (quote eod))  ;; End Of Data
               )))


(defn device-get-data [port]
  (run port `(gdt)))


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


(defn read-data [port]
  (let [[read-line* (fn [] (read-line port))]
        [data?      (fn [line] (not (.startswith line "eod")))]
        [to-dict    (fn [data]  ;; assoc is not pure
                      (setv d {})
                      (for [[type [id value]] data]
                        (if-not (in type (.keys d)) (assoc d type {}))
                        (assoc (get d type) id value))
                      d)]]
    (device-get-data port)
    (->> (repeatedly read-line*)
      (take-while data?)
      (map parse-data)
      (filter identity)  ;; empty or invalid lines
      to-dict)))


(defn read-data-stream [port]
  (device-init-knobs       port)
  (device-defun-print-knob port)
  (device-defun-get-data   port)

  (repeatedly (fn [] (read-data port))))


(on-serial "/dev/ttyUSB0"
           (fn [port]
             (->> (read-data-stream port)
               first
               print)
             ))
