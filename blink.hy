#!/usr/bin/env hy
(import [glia [on-serial run]])


(defn blink-led [device pin delay]
  (run device `(pinmode ~pin t))
  (run device `(defun blk ()
                 (digitalwrite ~pin t)
                 (delay ~delay)
                 (digitalwrite ~pin nil)
                 (delay ~delay)
                 (blk)))
  (run device `(blk)))


(on-serial "/dev/ttyUSB0"
           (fn [device]
             (blink-led device 13 500)
             ))
