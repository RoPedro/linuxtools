#!/bin/bash

# Installing btop
git clone https://github.com/aristocratos/btop.git

cd btop

make
sudo make install

cd ..
