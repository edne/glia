#!/usr/bin/env hy
(import serial)


(defn on-serial [path body]
  (with [[port (serial.Serial path 9600)]]
    (try
      (body port)
      (except [KeyboardInterrupt]
        (print "\rKeyboard Iterrupt")))))


(defn read-char [port]
  (-> port
    .read
    (.decode "ascii")))


(defn read-line [port]
  (->> (repeatedly (fn [] (read-char port)))
    (take-while (fn [c] (!= c "\n")))
    (.join "")))


(defn read-until [port match]
  (defn read-until* [text]
    (if (.endswith text match)
      text
      (read-until* (+ text (read-char port)))))
  (read-until* ""))


(defn wait-prompt [port]
  (read-until port " ~> "))


;; It doesn't work with strings and quotes!
;; Use (quote ...) instead of '(...)
(defn prettify [expr]
  (-> expr
    str
    (.replace "'" "")
    (.replace "None" "nil")))


(defn run [port command]
  (wait-prompt port)
  (let [[command* (prettify command)]]
    (print command*)
    (.write port (bytes command* "ascii")))
  (read-line port))


(defn device-defn [port body]
  (let [[name (first body)]]
    (run port (cons 'defun body))
    (fn [&rest args] (run port `(~name ~@args)))))
