#!/usr/bin/env hy
(import serial)
(import liblo)


;; uLisp and serial

(defn on-serial [path body]
  (with [[device (serial.Serial path 9600)]]
    (try
      (body device)
      (except [KeyboardInterrupt]
        (print "\rKeyboard Iterrupt")))))


(defn read-char [device]
  (-> device
    .read
    (.decode "ascii")))


(defn read-line [device]
  (->> (repeatedly (fn [] (read-char device)))
    (take-while (fn [c] (!= c "\n")))
    (.join "")))


(defn read-until [device match]
  (defn read-until* [text]
    (if (.endswith text match)
      text
      (read-until* (+ text (read-char device)))))
  (read-until* ""))


(defn wait-prompt [device]
  (read-until device " ~> "))


;; It doesn't work with strings and quotes!
;; Use (quote ...) instead of '(...)
(defn prettify [expr]
  (-> expr
    str
    (.replace "'" "")
    (.replace "None" "nil")))


(defn run [device command]
  (wait-prompt device)
  (let [[command* (prettify command)]]
    ;(print command*)
    (.write device (bytes command* "ascii")))
  (read-line device))


;; OSC

(defn to-osc [ip-port body]
  (let [[addr (->> ip-port
                (.format "osc.udp://{}")
                liblo.Address)]]
    (body addr)))


(defn send [addr path value]
  (liblo.send addr path value))
