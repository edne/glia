#!/usr/bin/env hy
(import [glia [with-serial run-command]])


(defn blink-led [port pin delay]
  (run-command port `(pinmode ~pin t))
  (run-command port `(defun blk ()
                       (digitalwrite ~pin t)
                       (delay ~delay)
                       (digitalwrite ~pin nil)
                       (delay ~delay)
                       (blk)))
  (run-command port `(blk)))


(with-serial (fn [port]
               (blink-led port 13 500)
               ))
