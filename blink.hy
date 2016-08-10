#!/usr/bin/env hy
(import [glia [on-serial run]])


(defn blink-led [port pin delay]
  (run port `(pinmode ~pin t))
  (run port `(defun blk ()
               (digitalwrite ~pin t)
               (delay ~delay)
               (digitalwrite ~pin nil)
               (delay ~delay)
               (blk)))
  (run port `(blk)))


(on-serial "/dev/ttyUSB0"
             (fn [port]
               (blink-led port 13 500)
               ))
