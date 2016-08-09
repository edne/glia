#!/usr/bin/env hy
(import serial)
(import re)


(defn with-serial [body]
  (with [[port (serial.Serial "/dev/ttyUSB0" 9600)]]
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


(defn remove-newlines [text]
  (.join " " (.split text "\n")))


;; It doesn't work with strings and quotes!
;; Use (quote ...) instead of '(...)
(defn prettify [expr]
  (-> expr
    str
    (.replace "'" "")
    (.replace "None" "nil")))


(defn run-command [port command]
  (wait-prompt port)
  (let [[command* (prettify command)]]
    (print command*)
    (.write port (bytes command* "ascii")))
  (read-line port))


(defn read-lines [port]
  (while true
    (yield (read-line port))))


(defn blink-led [port pin delay]
  (run-command port `(pinmode ~pin t))
  (run-command port `(defun blk ()
                       (digitalwrite ~pin t)
                       (delay ~delay)
                       (digitalwrite ~pin nil)
                       (delay ~delay)
                       (blk)))
  (run-command port `(blk)))


(defn device-init-knobs [port]
  (for [pin (range 7 22)]
    (run-command port `(pinmode ~pin nil))))


(defn device-defun-print-knob [port]
  (run-command port `(defun pkn (pin)
                       (print (quote >))
                       (princ (quote knb))
                       (princ (- pin 14))
                       (princ (quote =))
                       (princ (analogread pin))
                       )))


(defn device-defun-loop [port]
  (run-command port `(defun lop ()
                       (dotimes (kn 7)
                         (pkn (+ kn 14)))
                       (print (quote eod))  ;; End Of Data
                       (lop))))


(defn device-loop [port]
  (run-command port `(lop)))


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
    (->> (repeatedly read-line*)
      (take-while data?)
      (map parse-data)
      (filter identity)  ;; empty or invalid lines
      to-dict)))


(defn read-knobs [port]
  (device-init-knobs       port)
  (device-defun-print-knob port)
  (device-defun-loop       port)

  (device-loop port)
  ;(for [line (read-lines port)]
  ;  (print line))
  (print (read-data port))
  )


(with-serial (fn [port]
               ;(blink-led port 13 500)
               (read-knobs port)
               ))
