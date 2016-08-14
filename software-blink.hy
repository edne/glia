#!/usr/bin/env hy
(import [time [sleep]])
(import [glia [on-serial write-digital]])



(defn blink-led [device pin delay]
  (while true
    (write-digital device pin 1)
    (sleep delay)
    (write-digital device pin 0)
    (sleep delay)))


(on-serial "/dev/ttyUSB0"
           (fn [device]
             (blink-led device 13 0.5)
             ))
