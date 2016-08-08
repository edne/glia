#!/usr/bin/env hy
(import serial)


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


(defn run-command [port command]
  (wait-prompt port)
  (.write port (-> command
                 remove-newlines
                 (bytes "ascii")))
  (read-line port))


(defn read-lines [port]
  (while true  ;; TODO: special line to denote end-of-stream
    (yield (read-line port))))


(defn blink-led [port pin delay]
  (run-command port (.format
                      "(pinmode {} t)" pin))
  (run-command port (.format
                      "(defun blk ()
                         (digitalwrite {} t)
                         (delay {})
                         (digitalwrite {} nil)
                         (delay {})
                         (blk))" pin delay pin delay))
  (run-command port "(blk)"))


(defn read-knob [port pin]
  (run-command port (.format
                      "(pinmode {} nil)" pin))
  (run-command port (.format
                      "(defun kn ()
                         (print (analogread {}))
                         (kn))" pin))
  (run-command port "(kn)")
  (for [line (read-lines port)]
    (print line)))


(with-serial (fn [port]
               ;(blink-led port 13 500)
               (read-knob port 14)
               ))
