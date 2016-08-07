#!/usr/bin/env hy
(import serial)


(defn with-serial [body]
  (with [[port (serial.Serial "/dev/ttyUSB0" 9600)]]
    (body port)))


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
  (let [[prompt " ~> "]]
    (read-until port " ~> ")))


(defn run-command [port command]
  (wait-prompt port)
  (.write port (bytes command "ascii"))
  (read-line port))


(with-serial (fn [port]
               (run-command port "(+ 1 2)")
               (print (read-line port))
               (run-command port "(+ 4 2)")
               (print (read-line port))
               ))
