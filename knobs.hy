#!/usr/bin/env hy
(import [glia [on-serial to-osc send-analog]])


(to-osc "localhost:7172"
        (fn [addr]
          (on-serial "/dev/ttyUSB0"
                     (fn [device]
                       ; (send-analog device addr osc-path pin)
                       (while true
                         (send-analog device addr
                                      "/controller/knob0" 14))))))
