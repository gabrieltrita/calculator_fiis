#!/bin/bash
echo 'executando o restart ...'
# kill off old version, avoid killing random ruby processes
pkill ruby
kill -9 `lsof -t -i:4567`

# run it again but don't wait for it to finish
ruby calcular_dy.rb &
disown