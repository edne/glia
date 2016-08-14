#!/usr/bin/env hy
(import serial)
(import liblo)


;; uLisp and serial

(defn on-serial [path body]
  (try
    (with [[device (serial.Serial path 9600)]]
      (body device))
    (except [KeyboardInterrupt]
      (print "\rKeyboard Iterrupt"))
    (except [serial.serialutil.SerialException]
      (print "Serial port not found"))))


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


(def -pins-io-status- {})


(defn read-analog [device pin]
  (when (or
          (not (in pin -pins-io-status-))
          (= (get -pins-io-status- pin) "out"))
    (run device `(pinmode ~pin nil))
    (assoc -pins-io-status- pin "in"))

  (run device `(print (analogread ~pin)))
  (read-line device)      ; empty line
  (-> (read-line device)
    .split first          ; line like: 123 123
    float (/ 1023)))      ; from 0 to 1023


;; OSC

(defn to-osc [ip-port body]
  (let [[addr (->> ip-port
                (.format "osc.udp://{}")
                liblo.Address)]]
    (body addr)))


(defn send [addr path value]
  (liblo.send addr path value))


(defn send-analog [device addr osc-path pin]
  (send addr osc-path
        (read-analog device pin)))
